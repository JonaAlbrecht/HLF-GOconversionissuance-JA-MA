#maxOutput = 10000 kilos of hydrogen per hour as per certificate
export maxOutput=$((10000/60))
echo $maxOutput
export randomLoss1=$((1 + $RANDOM % 1000))
export Kilosproduced=$(($maxOutput - $randomLoss1))
#emission intensity of 20kilos of CO2 per Kilos produced
export EmissionIntensityHydrogen=4,5
export EmissionsHydrogen=$(($Kilosproduced * $EmissionIntensityHydrogen))
export kwhperkilo=50
export UsedMWh=$(($Kilosproduced*$kwhperkilo/1000))
export ElapsedSeconds=60
