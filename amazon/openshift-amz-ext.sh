
# Configure an authorized key to provide the broker access
configure_authorized_key()
{
cat <<EOF >> /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDj4ywobxQXlb4ey+2NufOh9+W2BH5NS9a4+D4X7AaKSrgMfTr8P2YFsioFOXXcpjKZrC3HLb6T8ZBxbO5mnTfl9SVv9/gAZZulxXWH/+1P0OLmZQ6u/D0GK4zosRS278Benm6FgiRZSrJZlo+h4Lf4HxAogdiwCDVJs44HnwMWuEjgkOgI0RyQ7txdaZDrwqn8vZ1yh+9bW0HlJWm374lyoNbCJzTH0IQQCLMEnb7QsWzD7lgaNpnKoZeJjQFi0HDGluJt/P9NjyJg3pqnMrGOCkxPU1zT90s0yCGkSUQ1xTJciBQOdffSQj7BAKGSqZxpM2iH8fZUPrpnUxQaXTRh
EOF
}

# Configure the private key on the broker to have named access
configure_private_key()
{
cat <<EOF > /root/.ssh/named_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA4+MsKG8UF5W+HsvtjbnzoffltgR+TUvWuPg+F+wGikq4DH06
/D9mBbIqBTl13KYymawtxy2+k/GQcWzuZp035fUlb/f4AGWbpcV1h//tT9Di5mUO
rvw9BiuM6LEUtu/AXp5uhYIkWUqyWZaPoeC3+B8QKIHYsAg1SbOOB58DFrhI4JDo
CNEckO7cXWmQ68Kp/L2dcofvW1tB5SVpt++JcqDWwic0x9CEEAizBJ2+0LFsw+5Y
GjaZyqGXiY0BYtBwxpbibfz/TY8iYN6apzKxjgpMT1Nc0/dLNMghpElENcUyXIgU
DnX30kI+wQChkqmcaTNoh/H2VD66Z1MUGl00YQIDAQABAoIBAQCkAAz7XFUdVApq
p1/iKvyGh5ytDTbH8dgpbZ1iId3jEDq74jPc7NNDLiDHeb60eHbZ2Oto+Ca62ZGV
z0sSVfqwZ2f12IKF5pnJBv26Thg+5JkmLXwPuj9AfX7+xtGdhZTvgx0Ov8Xg7LzF
dHERkmNTESfTvv5uULnovGtuWKUkZ0d1OJRY4uRFtilEawzeDcs6VCBUSxAKdTgI
p+wH3h2+IOqdMCle7mKt/k3pHDvjVkity3JE1G++m117C5ndUUEoizl9jHzVB0O+
sQaHVLDYZjeLmLS6mHv3EuAK86ZKiZ+kwRehnTnZnrj4tp8l3bZaFLa+thZdCI/E
QD7LoGCxAoGBAPYj8809V/w7mHZ9S7nDcKxvDbQU/Cm3tBW8JVCvFOBPnJbTUaGA
+lKM0Mob2lai6LyvG4RnqpZorQua4Ikb4H5kEti6I0MuVDadOCxLIi6iVSgjX185
hKsvszLEOHXf8BiqkOYbzUCXLdznMVlATNvyzAinJnOyrdaTGziXybfzAoGBAO0E
C1NHtdjVjWB/rCb2f+zKooBNIqo7K6oC6y+YDScgjHw2255w+uCG1sBgiKwHj1kE
lSp/mN0Af03eKshB1wIz5i83PNW2KvV1a2QWkf9ojbw6oPFGZWOOSGpycjJpzrSS
ai7d5fHsVDi7eyEsXNDVht+WjxTXSTdOIMiI8StbAoGBAKfIxi6HvGxiK4HJ007j
3PCOGydAjsvZP9b5E+62CmMFodZmYmTXSMvw1XqQFfusvT2xl+5fxDcXT65zes+7
wwIlMXuvFs56zEkWTu5SoRBs8+OSiTaePMN8lojqnRos9ru5uWBCX13CMC8/IbKX
VE0yascTOfDwQfPc/1dKkOTlAoGBAJxxgPA1cyhuvOSnIQCO0B2CGwTI5Uqrx8Ru
LMK7gGMFLvWGWCwast2k4vcUQOIcE1hUmAj3M/UcMOs6685G9x5zF0qvES6XEX/3
Qy1LYI7Pek51/GmFZ8Lw1Ye9hvcTs+aohgHtYavvrB/OUBWzbIhDiMToYgUFnUQu
A6GaEmXlAoGAJEJ7t+7joQ9TeIoSWlifTWz63biX5B2QLLQeI7ObAjrdj3iDo4De
UAhplvCUbVcZ3aVFYbofhd6Fyh7eR2RdPD/uWcsWeDkaO1lRXLrvTEgvlpFD//SU
EWGodSkqrF8f+Gdj1c7fZdc4XRygiOs/596K118fkehXXYtqs3JyXGs=
-----END RSA PRIVATE KEY-----
EOF

chmod 700 /root/.ssh/named_rsa
}

# Configure a default user
configure_default_user()
{
  htpasswd -b -c /etc/openshift/htpasswd demo changeme
}


set_dns_key()
{
  SSH_CMD="ssh -n -o TCPKeepAlive=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -i /root/.ssh/named_rsa"
  KEY=$(${SSH_CMD} ${named_hostname} "grep Key: /var/named/K${domain}*.private | cut -d ' ' -f 2")
}

# Amazon machines have fully qualified hostname
configure_node_amz()
{
  sed -i -e "s/^PUBLIC_HOSTNAME=.*$/PUBLIC_HOSTNAME=${hostname}/" /etc/openshift/node.conf
}

# Configures named with the correct public IP
configure_named_amz()
{
  # Get the public ip address
  IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

  # Replace the bind configuration with the public ip address
  sed -i -e "s/A 127.0.0.1/A ${IP}/" /var/named/dynamic/${domain}.db
}

named && configure_authorized_key
named && configure_named_amz

# Re-run the DNS plugin configuration after establishing the DNS key
broker && configure_private_key
broker && set_dns_key
broker && configure_dns_plugin
broker && configure_default_user

# Re-configure the node hostname for Amazon hosts
node && configure_node_amz

# Important - the callback is only working
# if the file data is sent up.  Probably related
# to the newlines after the initial brace.
cat <<EOF > /tmp/success_data
{
  "Status" : "SUCCESS",
  "Reason" : "Configuration Complete",
  "UniqueId" : "$1",
  "Data" : "Component has completed configuration."
}
EOF

echo "Calling wait URL..."
curl -T /tmp/success_data $2
echo "Done"

echo "Restarting VM"
reboot
