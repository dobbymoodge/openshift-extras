module OpenShift
  module Brew

    include OpenShift::Tito

    # Public: Obtain the set of packages needing to be taggedin to stage
    # 
    # source  - The source brew tag to lookup (example: libra-rhel-6-candidate)
    # target  - The target brew tag to lookup (example: libra-rhel-6-stage)
    # date    - Date since last stage: remove brew obsoletes (ex: 2012-04-15)
    # include_internal - Boolean indicating whether to include internal packages
    #
    # Examples:
    #   get_packages_to_tag("libra-rhel-6-candidate", "libra-rhel-6-stage", "2012-04-15")
    #   # => ["rhc-0.91.12-1.el6_2", "rhc-broker-0.91.18-1.el6_2"]
    #
    # Returns an array of brew package names
    def get_packages_to_tag(source, target, date, include_internal=false)
  
      stage_candidates = []   # store candidates from brew query
      need_stage_tags = []    # final set of packages that need tagging
      our_pkgs = []           # our packages w/ full version from brew query
      our_pkgs_names = include_internal ? {} : get_packages # <-- from Tito

      # FIXME:  I'm open to suggestion about the awk, I just couldn't think of a
      #         more clean implementation to get only tagged lines and the pkg
      source_pkgs = `brew -q latest-pkg #{source} --all \
                                              | awk '{print $1}'`.split("\n")
      target_pkgs = `brew -q latest-pkg #{target} --all \
                                              | awk '{print $1}'`.split("\n")

      # Find which packages are new since last stage
      source_pkgs.each do | pkg |
        stage_candidates.push( pkg ) unless target_pkgs.include? pkg
      end

      # Find which packages belong to us
      stage_candidates.each do | stg_candidate_pkg |
        our_pkgs_names.each do | pkg, paths |
          #if stg_candidate_pkg =~ /#{pkg}-\d+\.\d+.*/
          if stg_candidate_pkg =~ /#{pkg}(-[^-]+-[^-]+$)/
            our_pkgs.push(stg_candidate_pkg)
          end
        end
      end

      # Now put it all together (remove our_pkgs and obsoletes)
      stage_candidates.each do | pkg |

        # Special thanks to markllama, tdawson, and kwoodson for helping on this
        # little nugget - strips off the Version-Release from pkg build
        pkg_base_name = pkg.match(/(.*)(-[^-]+-[^-]+$)/)[1]
        
        # FIXME - This takes forever to run because of the brew query for each
        #         candidate package. Not sure of a better way to fix just yet.
        brew_recent_activity = `brew list-history --tag=#{source} \
                                --package=#{pkg_base_name} \
                                --after=#{date}` unless our_pkgs.include? pkg
        
        # FIXME - hack to get around ruby fail
        # For some reason ruby's ` ` operator is returning nil intermittently
        # and I've run through enough command strings that it claimed to be nil
        # to conclude that its just incorrect.
        if brew_recent_activity.nil?
          brew_recent_activity = "RUBY FAILS"
        end

        # Add to need_stage_tags unless it is one of ours or if there's been no
        # recent activity in brew
        need_stage_tags.push( pkg ) unless brew_recent_activity.empty? \
                                            or our_pkgs.include? pkg
      end
      
      need_stage_tags
    end

    def brew_move_pkg (src_brew_tag, target_brew_tag, pkg)
      tag_failures = ""
      pkg_name = pkg.split('-')[0...-2].join('-')
      brew_cmd = "brew move-pkg #{src_brew_tag} #{target_brew_tag} #{pkg}"
      brew_untag_cmd = "brew untag-pkg --all #{src_brew_tag} #{pkg_name}"

      `#{brew_cmd}`
      if $?.exitstatus == 0
        puts "Tag #{pkg} into #{target_brew_tag} - Done"
        `#{brew_untag_cmd}`
        
        # Sanity check after untag operation because brew untag-pkg will exit
        # with 0 no matter what
        src_tag_pkg = `brew latest-pkg --quiet #{src_brew_tag} #{pkg_name}`.split[0]
        target_tag_pkg = `brew latest-pkg --quiet #{target_brew_tag} #{pkg_name}`.split[0]

        unless src_tag_pkg == target_tag_pkg
          tag_failures += "#{brew_untag_cmd}\n"
        end

        puts "Untag #{pkg_name} from #{src_brew_tag} - Done"
      else
        tag_failures += "#{brew_cmd}\n"
        tag_failures += "#{brew_untag_cmd}\n"
      end

      tag_failures.to_s
    end

  end
end
