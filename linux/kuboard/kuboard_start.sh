sudo docker run -d \
  --restart=unless-stopped \
  --name=kuboard \
  -e KUBOARD_ADMIN_DERAULT_PASSWORD='123456' \
  -p 10080:80/tcp \
  -p 20081:10081/tcp \
  -e KUBOARD_ENDPOINT="http://kuboard.k8s.domain.com" \
  -e KUBOARD_AGENT_SERVER_TCP_PORT="20081" \
  -v /data/kuboard-data:/data \
  harborrepo.domain.com/ops/kuboard:v3
