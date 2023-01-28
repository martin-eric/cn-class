SCRIPTV="0.2"
FILE=~/.myself

if [[ $EUID -eq 0 ]]; then
        echo "You cannot be a root user. " 2>&1
        exit 1
fi


if [ -f "$FILE" ]; then

        echo "You already set your prompt"

        read -p "Do you want to change it? (y or n) " -n 1 -r
        echo    # (optional) move to a new line
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
                echo "Cancelling ...."
                exit 1
        fi


else

        echo "Setting up your prompt for the first time"
fi

echo "What is your First name and Last name"?
read name

echo "What is your signum ?"
read signum
NEWPS1="($name - $signum)"

echo "your new prompt will be : $NEWPS1"


read -p "Confirm the information looks correct ? (y or n) " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
        exit 1
fi


#export PS1="$NEWPS1 $PS1"
echo "$NEWPS1" > ~/.myself

sed -i '/.myself/d' ~/.bashrc

echo "if [ -f ~/.myself ]; then PS1=\"\$(cat ~/.myself) \$PS1\"; fi" >> ~/.bashrc

. ~/.bashrc

echo "Prompt modification complete. Please log out of every sessions and log back in..."
