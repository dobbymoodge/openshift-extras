
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
