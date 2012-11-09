get_configured_ip_addr()
{
  # Use a subshell to avoid setting variables in the caller.
  (. /etc/openshift/node.conf;
   echo $PUBLIC_IP;)
}

get_current_ip_addr()
{
  /sbin/ip addr show dev eth0 | awk '/inet / { split($2,a,"/"); print a[1]; }'
}

configured_ip_addr=$(get_configured_ip_addr)
cur_ip_addr=$(get_current_ip_addr)

test "x$configured_ip_addr" = "x$cur_ip_addr" && exit 0

service named stop

sed -i -e "s/$configured_ip_addr/$cur_ip_addr/" \
 /var/named/dynamic/*.db \
 /etc/openshift/node.conf \
 /etc/openshift/plugins.d/openshift-origin-dns-bind.conf \
 /var/named/dynamic/demo.cloudydemo.com.db \
 /etc/resolv.conf

service named start

for service in activemq mongod mcollective openshift-broker openshift-console openshift-port-proxy httpd
do
  service "$service" restart
done

exit 0
