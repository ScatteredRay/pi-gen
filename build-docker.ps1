
Param(
    $ContainerName = "pigen_work",
    $Continue = $False
)

$ConfigFile = (Get-ChildItem config).FullName

$ContainerExists = (docker ps -a --filter name="$ContainerName" -q).Length -gt 0
$ContainerRunning = (docker ps --filter name="$ContainerName" -q).Length -gt 0

if($ContainerRunning) {
    Write-Host "The Build is already running."
    Exit
}

Write-Host "Container Exists $ContainerExists Running $ContainerRunning"

if($ContainerExists -and !$Continue) {
    Write-Host "The Container already exists."
    #docker rm -v $ContainerName
}

docker build -t pi-gen .

if($ContainerExists) {
        docker run --rm --name "${ContainerName}_cont"  --volumes-from="${ContainerName}" --privileged --env-file $ConfigFile pi-gen bash -e -o pipefail -c "dpkg-reconfigure qemu-user-static && cd /pi-gen; ./build.sh; rsync -av work/*/build.log deploy/"
}
else {
    docker run --name "$ContainerName" --privileged --env-file $ConfigFile pi-gen bash -e -o pipefail -c "dpkg-reconfigure qemu-user-static && cd /pi-gen; ./build.sh; rsync -av work/*/build.log deploy/"
}

docker cp "${ContainerName}:/pi-gen/deploy" .

if(-not $Continue) {
    docker rm -v $ContainerName
}
