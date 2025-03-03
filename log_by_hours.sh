#!/bin/bash

# Prompt user for the application name
read -p "Enter the application name: " app_name

# Prompt user for the log duration (e.g., 2h, 30m, 1d)
read -p "Enter the log time duration (e.g., 2h, 30m, 1d): " log_duration

# Validate inputs
if [[ -z "$app_name" || -z "$log_duration" ]]; then
    echo -e "\n\e[1;31mError: Both application name and log duration are required.\e[0m"
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

# Print Main Heading
echo -e "\n\e[1;36m═════════════════════════════════════════════════════════════════════════════\e[0m" | append_and_display
echo -e "\e[1;35m         Traffic Analysis Report for Application: $app_name ($log_duration)         \e[0m" | append_and_display
echo -e "\e[1;36m═════════════════════════════════════════════════════════════════════════════\e[0m\n" | append_and_display

# Section 1: Top 10 IPs with Request Count and Status Codes
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m" | append_and_display
echo -e "\e[1;33m📌 Top 10 IPs with Count, URLs, and Request Status ($log_duration)\e[0m" | append_and_display
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m\n" | append_and_display
apm -s "$app_name" traffic --ips -l "$log_duration" | append_and_display
echo -e "\n" | append_and_display

# Add Country Details for IPs
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m" | append_and_display
echo -e "\e[1;33m🌍 Country Details for Above IPs\e[0m" | append_and_display
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m\n" | append_and_display

# Fetch and display country details for each IP
apm -s "$app_name" traffic --ips -l "$log_duration" | awk 'NR>3 && $2 != "IP" && $2 != "" {print $2}' | while read -r ip; do
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
apm -s "$app_name" traffic --ips -l "$log_duration" | awk 'NR>3 && $2 != "IP" && $2 != "" {print $2}' | while read -r ip; do
    host "$ip" | append_and_display
done
echo -e "\n" | append_and_display

# Section 3: URLs with Count and Status Code per IP
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m" | append_and_display
echo -e "\e[1;33m🔗 URLs with Count and Status Code Accessed by Above IPs\e[0m" | append_and_display
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m\n" | append_and_display
apm -s "$app_name" traffic --ips -l "$log_duration" | awk 'NR>3 && $2 != "IP" && $2 != "" {print $2}' | while read -r ip; do
    apm -s "$app_name" traffic --ip "$ip" --statuses -l "$log_duration" | append_and_display
done
echo -e "\n" | append_and_display

# Section 4: Top 10 Most Accessed URLs
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m" | append_and_display
echo -e "\e[1;33m🔥 Top 10 Most Accessed URLs ($log_duration)\e[0m" | append_and_display
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m\n" | append_and_display
apm -s "$app_name" traffic --urls -l "$log_duration" | append_and_display
echo -e "\n" | append_and_display

# Section 5: IPs Who Accessed the Most Accessed URLs
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m" | append_and_display
echo -e "\e[1;33m👥 IPs Who Accessed the Most Visited URLs with Count & Status Code\e[0m" | append_and_display
echo -e "\e[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m\n" | append_and_display
apm -s "$app_name" traffic --urls -l "$log_duration" | awk 'NR>3 && $2 != "URL" && $2 != "" {print $2}' | while read -r url; do
    apm -s "$app_name" traffic --url "$url" --statuses -l "$log_duration" | append_and_display
done
echo -e "\n" | append_and_display
# Final Footer
echo -e "\e[1;36m═════════════════════════════════════════════════════════════════════════════\e[0m" | append_and_display
echo -e "\e[1;32m🚀 Traffic Analysis Completed for $app_name ($log_duration) 🚀\e[0m" | append_and_display
echo -e "\e[1;36m═════════════════════════════════════════════════════════════════════════════\e[0m\n" | append_and_display

# Create a zip file of the output
zip -j /tmp/output.zip "$output_file"

echo -e "\e[1;32mReport saved to $output_file and zipped to /tmp/output.zip\e[0m"
