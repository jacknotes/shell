import redis

def key_deleted(message):
    print(f"Key {message['data']} was deleted")

# 连接到 Redis
r = redis.StrictRedis()

# 订阅删除事件
p = r.pubsub()
p.psubscribe(**{'__keyevent@0__:del': key_deleted})

# 在后台运行订阅事件
p.run_in_thread(sleep_time=0.1)
