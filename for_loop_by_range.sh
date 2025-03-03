

#!/bin/bash

# Prompt user for the start date and time (e.g., 21/02/2025:00:00)
read -p "Enter the start date and time (MM/DD/YYYY:HH:MM): " start_time

# Prompt user for the end date and time (e.g., 21/02/2025:23:59)
read -p "Enter the end date and time (MM/DD/YYYY:HH:MM): " end_time

# Validate inputs
if [[ -z "$start_time" || -z "$end_time" ]]; then
    echo -e "\n\e[1;31mError: Start time and end time are required.\e[0m"
    exit 1
fi

# Output file path
output_file="/tmp/output.txt"

# Clear the output file if it exists
> "$output_file"

# Function to append output to file and display on terminal
append_and_display() {
    tee -a "$output_file"
}

# Get the server's public IP
server_ip=$(curl -s ipinfo.io/ip)

# Loop through all applications
for app_name in $(ls -l /home/master/applications/ | grep "^d" | awk '{print $NF}'); do
    # Get the server name from the Nginx configuration
    server_name=$(cat /home/master/applications/"$app_name"/conf/server.nginx | awk '/server_name/ {print $NF}' | tr -d ';')

    # Print Application Heading
    echo -e "\n\e[1;36m═════════════════════════════════════════════════════════════════════════════\e[0m" | append_and_display
    echo -e "\e[1;35m         Traffic Analysis Report for Application: $app_name (Server: $server_name)         \e[0m" | append_and_display
    echo -e "\e[1;35m         Time Range: From $start_time to $end_time         \e[0m" | append_and_display
    echo -e "\e[1;36m═════════════════════════════════════════════════════════════════════════════\e[0m\n" | append_and_display

    # Section 1: Top 10 IPs with Request Count and Status Codes
    echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m" | append_and_display
    echo -e "\e[1;33m📌 Top 10 IPs with Count, URLs, and Request Status (From $start_time to $end_time)\e[0m" | append_and_display
    echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m\n" | append_and_display
    apm -s "$app_name" traffic --ips --from "$start_time" --until "$end_time" | append_and_display
    echo -e "\n" | append_and_display

    # Add Country Details for IPs
    echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m" | append_and_display
    echo -e "\e[1;33m🌍 Country Details for Above IPs\e[0m" | append_and_display
    echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m\n" | append_and_display

    # Fetch and display country details for each IP
    apm -s "$app_name" traffic --ips --from "$start_time" --until "$end_time" | awk 'NR>3 && $2 != "IP" && $2 != "" {print $2}' | while read -r ip; do
        country=$(curl -s "http://ip-api.com/line/$ip?fields=country")
        # Check if the IP is the server's IP
        if [[ "$ip" == "$server_ip" ]]; then
            ip_info="        --> IT IS YOUR SERVER IP"
        else
            ip_info=""
        fi
        echo -e "IP: $ip | Country: $country $ip_info" | append_and_display
    done
    echo -e "\n" | append_and_display

    # Section 2: Translate IPs to Domain Names (Where Possible)
    echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m" | append_and_display
    echo -e "\e[1;33m🌍 Translated Domain Names (Owner Details of Above IPs)\e[0m" | append_and_display
    echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m\n" | append_and_display
    apm -s "$app_name" traffic --ips --from "$start_time" --until "$end_time" | awk 'NR>3 && $2 != "IP" && $2 != "" {print $2}' | while read -r ip; do
        host "$ip" | append_and_display
    done
    echo -e "\n" | append_and_display

    # Section 3: URLs with Count and Status Code per IP
    echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m" | append_and_display
    echo -e "\e[1;33m🔗 URLs with Count and Status Code Accessed by Above IPs\e[0m" | append_and_display
    echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m\n" | append_and_display
    apm -s "$app_name" traffic --ips --from "$start_time" --until "$end_time" | awk 'NR>3 && $2 != "IP" && $2 != "" {print $2}' | while read -r ip; do
        apm -s "$app_name" traffic --ip "$ip" --statuses --from "$start_time" --until "$end_time" | append_and_display
    done
    echo -e "\n" | append_and_display

    # Section 4: Top 10 Most Accessed URLs
    echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m" | append_and_display
    echo -e "\e[1;33m🔥 Top 10 Most Accessed URLs (From $start_time to $end_time)\e[0m" | append_and_display
    echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m\n" | append_and_display
    apm -s "$app_name" traffic --urls --from "$start_time" --until "$end_time" | append_and_display
    echo -e "\n" | append_and_display

    # Section 5: IPs Who Accessed the Most Accessed URLs
    echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m" | append_and_display
    echo -e "\e[1;33m👥 IPs Who Accessed the Most Visited URLs with Count & Status Code\e[0m" | append_and_display
    echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m\n" | append_and_display
    apm -s "$app_name" traffic --urls --from "$start_time" --until "$end_time" | awk 'NR>3 && $2 != "URL" && $2 != "" {print $2}' | while read -r url; do
        apm -s "$app_name" traffic --url "$url" --statuses --from "$start_time" --until "$end_time" | append_and_display
    done
    echo -e "\n" | append_and_display

    # Final Footer for Application
    echo -e "\e[1;36m═════════════════════════════════════════════════════════════════════════════\e[0m" | append_and_display
    echo -e "\e[1;32m🚀 Traffic Analysis Completed for $app_name (From $start_time to $end_time) 🚀\e[0m" | append_and_display
    echo -e "\e[1;36m═════════════════════════════════════════════════════════════════════════════\e[0m\n" | append_and_display
done

# Create a zip file of the output
zip -j /tmp/output.zip "$output_file"

echo -e "\e[1;32mReport saved to $output_file and zipped to /tmp/output.zip\e[0m"
