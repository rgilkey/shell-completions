CUSTOM_DIR="${HOME}/.zsh-functions"
mkdir ${CUSTOM_DIR}
cat << EOF > ${CUSTOM_DIR}/_start_session
#compdef start_session

local state

_arguments \
  '*:instance:->instances' \
  && return 0

case $state in
  instances)
    _describe 'instance-id' "($(aws ec2 describe-instances \
      --query "Reservations[*].Instances[*].[InstanceId, Tags[?Key=='Name'].Value | [0]]" \
      --filters Name=instance-state-name,Values=running \
      --output text \
      | tr '\t' ':'))"
    ;;
esac
EOF
echo 'alias start_session="aws ssm start_session --target"' >> .zshrc
echo 'fpath=("${CUSTOM_DIR}" ${fpath})' >> .zshrc
