echo -e "Save model locally?\n1=Yes\n0=No"
read save_local

if [[ "$save_local" == "1" || "$save_local" == "0" ]]; then

    docker run \
    -it \
    --rm \
    -v "$(pwd)"/artifacts:/root/toolkit/artifacts \
    -e SAVE_LOCAL=$save_local rkllm

    echo Enter sudo password to give your user rights to the file

    sudo chown -R $(id -u):$(id -g) ./artifacts # give user rights to artifacts

else
    echo Invalid entry!
fi
