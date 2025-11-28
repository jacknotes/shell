#!/bin/bash

#set -euo pipefail  # 更安全的脚本执行模式

SCRIPT_NAME="$0"
ACTION="$1"
NAMESPACE="$2"
RS_NAME="$3"

# 检查参数数量和格式
check_args() {
    if [[ $# -ne 3 ]]; then
        echo "用法: $SCRIPT_NAME {list|run|show} NAMESPACE RS_NAME" >&2
        echo "RS_NAME 示例: pro-java-traininvoicemanager-service-hs-com-rollout-785f98 (只能包含6位哈希前缀)" >&2
        exit 1
    fi

    # 可选：检查 RS_NAME 是否包含至少6位十六进制后缀（如 785f98）
    if [[ ! "$RS_NAME" =~ [a-f0-9]{6,6}$ ]]; then
        echo "警告: RS_NAME 似乎不包含有效的6位哈希前缀（如 ...-785f98）" >&2
        # 可选：exit 1 或仅警告
    fi
}

# 列出匹配的 Pod
list_pods() {
    #kubectl get pods -n "$NAMESPACE" -o name | grep -F "$RS_NAME" || true
    kubectl get pods -n "$NAMESPACE" | grep -F "$RS_NAME" || true
}

# 获取第一个 Running 状态的 Pod 名称（不含 "pod/" 前缀）
get_running_pod() {
    local pod_full
    pod_full=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{range .items[?(@.status.phase=="Running")]}{.metadata.name}{"\n"}{end}' 2>/dev/null | grep -F "$RS_NAME" | head -n1)
    if [[ -z "$pod_full" ]]; then
        echo "错误: 未找到处于 Running 状态的 Pod，RS_NAME: $RS_NAME" >&2
        return 1
    fi
    echo "$pod_full"
}

# 删除匹配的 Pod（滚动重启）
delete_pods() {
    local pods
    mapfile -t pods < <(kubectl get pods -n "$NAMESPACE" -o name | grep -F "$RS_NAME" | sed 's|pod/||')
    if [[ ${#pods[@]} -eq 0 ]]; then
        echo "警告: 未找到匹配的 Pod，RS_NAME: $RS_NAME"
        return 0
    fi

    echo "正在删除以下 Pod: ${pods[*]}"
    kubectl delete pod -n "$NAMESPACE" "${pods[@]}"
}

# 实时查看日志（支持多个日志文件）
show_logs() {
    local pod_name="$1"
    echo "正在连接到 Pod: $pod_name 查看日志（按 Ctrl+C 退出）..."
    # -F = --follow=name --retry, 即使日志被轮转（比如 logrotate 把 app.log 改名为 app.log.1，并新建一个 app.log），tail -F 仍会继续追踪新创建的同名文件。--retry 如果文件暂时不存在，tail 不会退出，而是不断尝试重新打开它，直到文件出现。
    kubectl exec -n "$NAMESPACE" "$pod_name" -- sh -c 'tail -F -n 100 /logs/*.log 2>/dev/null || echo "日志文件 /logs/*.log 不存在或不可读"'
}

case "$ACTION" in
    list)
        check_args "$@"
        list_pods
        ;;
    run)
        check_args "$@"
        delete_pods
        echo "等待新 Pod 启动中..." >&2
        sleep 5  # 简单等待，可改进为 watch

        if ! pod=$(get_running_pod); then
            exit 1
        fi

        show_logs "$pod"
        ;;
    show)
        if ! pod=$(get_running_pod); then
            exit 1
        fi

        show_logs "$pod"
	;;
    *)
        echo "用法: $SCRIPT_NAME {list|run|show} NAMESPACE RS_NAME" >&2
        exit 1
        ;;
esac
