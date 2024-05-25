DIRECTORY=/usr/local/go/src/github.com/JonaAlbrecht/HLF-GOconversionissuance-JA-MA/version1/setup1/issuer-vm3
export VERSION="1"
export CC_NAME="conversion" 
export var=$(cat $DIRECTORY/log.txt)
echo $var
export PACKAGE_ID=$(start=56; stop=119; echo $var| cut -c $start-$stop)
#export PACKAGE_ID=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" $var)
echo $PACKAGE_ID