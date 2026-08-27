export $(cat .env | xargs) && databricks bundle deploy


databricks bundle deploy    --var="day=05"   --var="month=12"   --var="year=2023"   --var="base_url=https://d37ci6vzurychx.cloudfront.net/trip-data/"   --var="raw_path=/Volumes/nyc_taxi/bronze/raw_data/"


databricks bundle run  download_files   --params="day=05"   --params="month=07"   --params="year=2025"   --params="base_url=https://d37ci6vzurychx.cloudfront.net/trip-data/"   --params="raw_path=/Volumes/nyc_taxi/bronze/raw_data/"   
