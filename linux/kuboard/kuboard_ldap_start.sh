sudo docker run -d \
  --restart=unless-stopped \
  --name=kuboard \
  -p 10080:80/tcp \
  -p 20081:10081/tcp \
  -e KUBOARD_ENDPOINT="http://kuboard.k8s.domain.com" \
  -e KUBOARD_AGENT_SERVER_TCP_PORT="20081" \
  -v /data/kuboard-data:/data \
  -e KUBOARD_LOGIN_TYPE="ldap" \
  -e KUBOARD_ROOT_USER="0001" \
  -e LDAP_HOST="192.168.10.250:389" \
  -e LDAP_SKIP_SSL_VERIFY="true" \
  -e LDAP_BIND_DN="CN=域管理员,OU=Services,OU=Headquarter,DC=domain,dc=com" \
  -e LDAP_BIND_PASSWORD="123456" \
  -e LDAP_BASE_DN="OU=tech,OU=dep,OU=Users,OU=Headquarter,DC=domain,DC=com" \
  -e LDAP_FILTER="(objectClass=user)" \
  -e LDAP_ID_ATTRIBUTE="sAMAccountName" \
  -e LDAP_USER_NAME_ATTRIBUTE="sAMAccountName" \
  -e LDAP_EMAIL_ATTRIBUTE="mail" \
  -e LDAP_DISPLAY_NAME_ATTRIBUTE="displayName" \
  -e LDAP_GROUP_SEARCH_BASE_DN="OU=Roles,OU=Groups,OU=Headquarter,DC=domain,DC=com" \
  -e LDAP_GROUP_SEARCH_FILTER="(objectClass=group)" \
  -e LDAP_USER_MACHER_USER_ATTRIBUTE="memberOf" \
  -e LDAP_USER_MACHER_GROUP_ATTRIBUTE="DistinguishedName" \
  -e LDAP_GROUP_NAME_ATTRIBUTE="name" \
  harborrepo.domain.com/ops/kuboard:v3
