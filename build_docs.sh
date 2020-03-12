echo "Generating Documentation.  "
echo "Make sure you have Jazzy installed."
echo "Jazzy is here: https://github.com/realm/jazzy"
echo "To install Jazzy: [sudo] gem install jazzy"

cd FIOSDK
jazzy --include=FIOSDK/FIOSDK.swift,FIOSDK/Core/BaseFIOSDK.swift,FIOSDK/Core/Helpers/SUFUtils.swift

echo "Documentation will be here: "
echo "    FIOSDK/docs"