Param(
    $ContainerName = "pigen_work"
)

$IMG_NAME = "nd_screen"

$ConfigFile = (Get-ChildItem config).FullName

$ContainerExists = (docker ps -a --filter name="$ContainerName" -q).Length -gt 0
$ContainerRunning = (docker ps --filter name="$ContainerName" -q).Length -gt 0

if($ContainerRunning) {
    Write-Host "The Build is already running."
    Exit
}

if($ContainerExists) {
    Write-Host "The Container already exists."
    docker rm -v $ContainerName
}

docker build -t pi-gen .

docker run --name "$ContainerName" --privileged --env-file $ConfigFile pi-gen bash -e -o pipefail -c "dpkg-reconfigure qemu-user-static && cd /pi-gen; ./build.sh; rsync -av work/*/build.log deploy/"

#docker cp "$ContainerName":/pi-gen/deploy .

#docker rm -v $ContainerName
