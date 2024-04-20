export maxOutput=$((10000))
export randomLoss1=$((1 + $RANDOM % 1000))
export Kilosproduced=$(($maxOutput - $randomLoss1))
export perminute=$(($Kilosproduced/60))
#emission intensity of 4 of CO2 per Kilos produced
    export EmissionIntensityHydrogen=4
    export EmissionsHydrogen=$(($perminute * $EmissionIntensityHydrogen))
    export kwhperkilo=50
    export UsedMWh=$(($perminute*$kwhperkilo/1000))
    export ElapsedSeconds=60
echo $EmissionsHydrogen