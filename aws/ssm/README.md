# Systems Manager

The AWS Systems Manager (SSM) Agent is a great tool for executing automations in the AWS environment. One particularly
great use case that the agent facilitates is SSH-less access to remote systems. Unlike the
[EC2 Instance Connect tool](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Connect-using-EC2-Instance-Connect.html)
SSM does not require leaving port 22 access open via security group. Similarly to EC2 Instance Connect, calls to start
sessions are logged via CloudTrail for audit history.

However, once you've got a lot of instances or your instances are changing dynamically, you need an efficient way to
initiate a session without having to look up EC2 instance information from the API or web console.

Autocompletions! This autocompletion works by hitting the EC2 API, gathering all the available EC2 instances and
presenting them for selection.

# Prerequisites

A few prerequisites are required:

* Either the `bash` or `zsh` shell. The completions will work on `zsh` with or without [`ohmyzsh`](https://ohmyz.sh/)
* The FZF package ([installation instructions](https://github.com/junegunn/fzf#installation)). You may need to enable
  the shell's completions. For example, when using `bash` on Debian/Ubuntu you need to:
  ```sh
  sudo cp /usr/share/doc/fzf/examples/completion.bash /etc/bash_completion.d/fzf
  ```
  And similarly on OS X via Homebrew:
  ```sh
  sudo cp /usr/local/Cellar/fzf/$( brew list fzf --versions | tail -n 1 | awk '{ print $2; }' )/shell/completion.bash /usr/local/etc/bash_completion.d/fzf
  ```

# Bash

## Configuration

To support `bash`, we'll utilize 3 components in our `~/.bashrc` file:

1. An alias for the command for brevity
2. A FZF completion function as well as a postprocessing function to print out the actual value needed for completion
3. A command to enable the completion in the shell

These items are shown below. The logic could also be abstracted to a separate file and sourced into the rc script.

```sh
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
```

## Usage

Once your shell is configured and the code is activated (if you didn’t reload your shell), you can begin using the tools.
Also, keep in mind you must have an up-to-date access token for the AWS CLI.

```sh
# Search all instances
$ start_session **<tab>

# Search for instances that match the phrase "log"
$ start_session log**<tab>
```

More informaion on search patterns can be found in the
[`fzf` documentation](https://github.com/junegunn/fzf#fuzzy-completion-for-bash-and-zsh).

# ZSH

## Configuration

For ZSH, we'll create a directory for your custom completions.  We’ll create a directory, drop the custom completion
in it, then add the directory to our `fpath` environment variable:

```sh
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
```

### Alias completions

If you don’t already have the option set, you’ll want to enable alias completion to prevent the command from being
expanded prior to autocompletion:

```sh
echo 'setopt completealiases' >> .zshrc
```

_*Note to `ohmyzsh` users:*_ You may need to add these lines to the top of your `.zshrc` prior to the `ohmyzsh`
initialization for it to work.

If for some reason you can't use the `completaliases` shell option - for example, you have a bunch of Git aliases
you want expanded for convenience - then you could create a simple wrapper script in your `$PATH` like so:

```sh
cat << EOF > /path/to/custom/in/path/start_session
#!/usr/bin/env zsh

aws ssm start-session --target "${1}"
EOF

chmod u+x /path/to/custom/in/path/start_session
```

This would allow you to maintain your existing alias configuration while taking advantage of the SSM autocompletions.

## Usage

To use the autocompletion, simply type `start_session` followed by a space and hit tab. The first tab keystroke will
begin the autocompletion, the second will show all available/matching options:

```sh
➜ ~ start_session <tab>
➜ ~ start_session i-0<tab>
```
