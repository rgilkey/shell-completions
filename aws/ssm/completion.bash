alias start_session="aws ssm start-session --target"

_fzf_complete_startsession() {
    ARGS="$@"

    if [[ $ARGS == 'start_session '* ]]; then
        _fzf_complete "--reverse --multi" "$@" < <(
            aws ec2 describe-instances \
                --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value | [0], InstanceId]" \
                --filters Name=instance-state-name,Values=running --output text | \
                sort -n -k 1 | \
                tr ' ' '-' | \
                column -t -s $'\t'
        )
    else
        eval "zle ${fzf_default_completion:-expand-or-complete}"
    fi
}

_fzf_complete_startsession_post() {
    awk '{print $2}'
}

[ -n "$BASH" ] && complete -F _fzf_complete_startsession -o default -o bashdefault start_session
