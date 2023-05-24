# author: Juwon1405

#!/usr/bin/env python3
# Python script to query reputation information for an IP address (basic information, SANS ICS, public cloud, CDN)
import requests  # HTTP 요청을 보내는 모듈
import xml.etree.ElementTree as ET  # XML 파싱을 위한 모듈
import html  # HTML 문자열을 디코딩하기 위한 모듈
import json  # JSON 파싱을 위한 모듈
import urllib.request  # URL을 다루기 위한 모듈
from ipaddress import ip_address, ip_network  # IP 주소와 네트워크를 다루기 위한 모듈
import pycountry  # 국가 코드를 다루기 위한 모듈
import re # 정규 표현식을 사용하기 위한 모듈
import sys
def find_isc_sans_ip_info(ip):
	# ISC SANS 웹 사이트에서 IP 정보를 가져오는 함수
	url = f"https://isc.sans.edu/api/ip/{ip}"
	response = requests.get(url)  # HTTP GET 요청을 보냄
	
	# HTTP 응답이 실패한 경우
	if not response.ok:
		print(f"Request failed with status code {response.status_code}.")
		return
	
	
	root = ET.fromstring(response.text)  # XML 파싱
	ip_data = { # 데이터를 저장할 딕셔너리(IP 주소 정보)
		"[ISC SANS]": f"https://isc.sans.edu/api/ip/{ip}", 
		"Updated:": root.findtext('updated') or "Not available",
		"Recent:": root.findtext('maxdate') or "Not available",
		"Oldest:": root.findtext('mindate') or "Not available",
		"Reported:": root.findtext("count") or "Not available",
		"Attacked:": root.findtext("attacks") or "Not available",
		"Maxrisk:": root.findtext('maxrisk') or "Not available",
		
		"IP address:": root.findtext("number") or "Not available",
		"AS Country:": (
			f"{root.findtext('ascountry')} ({pycountry.countries.get(alpha_2=root.findtext('ascountry', 'XX')).name})"
			if root.findtext("ascountry")
			else "Not available"
		),
		"AS ISP:": root.findtext("asname") or "Not available",
		"AS Number:": 'AS'+root.findtext("as") or "Not available",
		"AS Size:": format(int(root.findtext("assize") or 0), ",") or "Not available",
		"AS Subnet:": root.findtext("network") or "Not available",
		"AS Abuse Contact:": (
			html.unescape(root.findtext("asabusecontact") or "") if root.findtext("asabusecontact") else "Not available"
		),
		"Comment:": root.findtext('comment') or "Not available",
	}
	
	max_len = max(len(key) for key in ip_data.keys())  # 출력 시 각 항목의 이름 최대 길이를 계산
	for key, value in ip_data.items():
		if value != "Not available":
			print(f"{key:<{max_len}} {value:<35}")  # 좌측 정렬, 값은 최대 35자까지 출력
		#else: #Not available은 미출력
			#print(f"{key:<{max_len}} {value:<35}")  # 좌측 정렬, 값은 최대 35자까지 출력
			
			
			
def find_aws_ip_range(ip_address_str):
	# AWS IP 주소 범위 정보를 가져오는 함수
	url = "https://ip-ranges.amazonaws.com/ip-ranges.json"
	response = requests.get(url)  # HTTP GET 요청을 보냄
	data = json.loads(response.text)  # JSON 파싱
	
	# AWS IP 주소 범위 정보에서 입력한 IP 주소가 포함되는지 확인
	for prefix in data["prefixes"]:
		# IPv6 주소 범위일 경우
		if "ipv6_prefix" in prefix and ip_address(ip_address_str) in ip_network(prefix['ipv6_prefix']):
			ip_data = {
				"\n[AWS Range": f"{url}]",
				"SyncToken:": data['syncToken'],
				"CreateDate:": data['createDate'],
				"IP address:": ip_address_str,
				"IP range:": prefix['ipv6_prefix'],
				"AWS Service:": prefix['service'],
				"Region:": prefix['region']
			}
			break
		# IPv4 주소 범위일 경우
		if ip_address(ip_address_str) in ip_network(prefix['ip_prefix']):
			ip_data = {
				"\n[AWS Range]": f"{url}",
				"SyncToken:": data['syncToken'],
				"CreateDate:": data['createDate'],
				"IP address:": ip_address_str,
				"IP range:": prefix['ip_prefix'],
				"AWS Service:": prefix['service'],
				"Region:": prefix['region']
			}
			break
	else:
		# 입력한 IP 주소가 AWS IP 주소 범위에 속하지 않을 경우
		return None  # 반환값을 None으로 설정
	
	# 출력을 위한 최대 길이 설정
	max_len = max(len(key) for key in ip_data.keys())
	# AWS IP 정보 출력
	for key, value in ip_data.items():
		print(f"{key:<{max_len}} {value:<35}")
		
	return ip_data  # 결과를 반환
	# 출력을 위한 최대 길이 설정
	max_len = max(len(key) for key in ip_data.keys())
	# AWS IP 정보 출력
	for key, value in ip_data.items():
		print(f"{key:<{max_len}} {value:<35}")
		
def find_gcp_ip_range(ip_address_str):
	# GCP IP 주소 범위 정보를 가져오는 함수
	url = "https://www.gstatic.com/ipranges/cloud.json"
	response = requests.get(url)
	data = json.loads(response.text)
	
	for prefix in data["prefixes"]:
		# IPv4 주소인 경우
		if "ipv4Prefix" in prefix and ip_address(ip_address_str) in ip_network(prefix['ipv4Prefix']):
			ip_data = {
				"\n[GCP Range]": f"{url}",
				"IP address:": ip_address_str,
				"IP range:": prefix['ipv4Prefix'],
				"GCP Service:": prefix['service'],
				"Region:": prefix['scope']
			}
			break
		# IPv6 주소인 경우
		if "ipv6Prefix" in prefix and ip_address(ip_address_str) in ip_network(prefix['ipv6Prefix']):
			ip_data = {
				"\n[GCP Range]": f"{url}",
				"IP address:": ip_address_str,
				"IP range:": prefix['ipv6Prefix'],
				"GCP Service:": prefix['service'],
				"Region:": prefix['scope']
			}
			break
	else:
		# 입력한 IP 주소가 GCP IP 주소 범위에 속하지 않을 경우
		return None # 반환값을 None으로 설정
	
	# 결과 출력
	max_len = max(len(key) for key in ip_data.keys())
	for key, value in ip_data.items():
		print(f"{key:<{max_len}} {value:<35}")
		
		
		
		
def find_azure_ip_range(ip_address_str):
	# Azure IP 주소 범위 정보를 가져오는 함수
	url = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519"
	response = requests.get(url)  # HTTP GET 요청을 보냄
	
	# HTTP 응답이 실패한 경우
	if not response.ok:
		print(f"Request failed with status code {response.status_code}.")
		return None
	
	# HTML 문자열에서 IP 주소 범위 정보를 찾음
	html_text = response.text
	# 리다이렉션 URL을 찾음
	redirect_url = re.search(r"urlScrapeRedirect\": \"(https[^\"]*71D86715-5596-4529-9B13-DA13A5DE5B63[^\"]*json)", html_text)
	if not redirect_url:
		print("Failed to find Azure IP range JSON URL.")
		return None
	json_url = redirect_url.group(1).replace("\\", "")  # 역 슬래시 제거
	print(f"JSON URL: {json_url}")
	
	# JSON 파일에서 IP 주소 범위 정보를 찾음
	response = requests.get(json_url)
	if not response.ok:
		print(f"Request failed with status code {response.status_code}.")
		return None
	data = json.loads(response.text)
	for prefix in data["values"]:
		if ip_address(ip_address_str) in ip_network(prefix):
			ip_data = {
				"\n[Azure Range]": f"{url}",
				"IP address:": ip_address_str,
				"IP range:": str(prefix),
				"Service:": data["name"],
				"Region:": data["properties"]["region"]
			}
			# 결과를 출력하고 반환
			max_len = max(len(key) for key in ip_data.keys())
			for key, value in ip_data.items():
				print(f"{key:<{max_len}} {value:<35}")
			return ip_data
		
	# 입력한 IP 주소가 Azure IP 주소 범위에 속하지 않을 경우
	return None
def search_ip_info(ip):
	isc_sans_info = find_isc_sans_ip_info(ip)
	aws_range_info = find_aws_ip_range(ip)
	gcp_range_info = find_gcp_ip_range(ip)
	azure_range_info = find_azure_ip_range(ip)
	
	# IP 정보가 없을 경우 출력
	if aws_range_info is None:
		None #print(f"[AWS Range] {ip} is not an AWS IP address.\n")
	elif gcp_range_info is None:
		None #print(f"[GCP Range] {ip} is not a GCP IP address.\n")
	elif azure_range_info is None:
		None #print(f"[Azure] {ip} is not a Azure address.\n")
	elif isc_sans_info is None:
		None #print(f"[ICS SANS] {ip} is not a ICS SANS address.\n")
if __name__ == "__main__":
	if len(sys.argv) == 2:
		search_ip_info(sys.argv[1])
	else:
		print("Usage: ipcheck.py IP_ADDRESS")
			
#search_ip_info('157.245.244.222') # TEST IP Address
		
#search_ip_info('89.248.165.184') # SC Black IP
#search_ip_info('8.8.8.8') # Google DNS Server
	
#search_ip_info('203.104.134.20') # LINE Japan AS38631
#search_ip_info('125.209.252.18') # NAVER Cloud Korea AS23576
	
#search_ip_info('3.5.140.200') # AWS(Amazon Web Services) Range
#search_ip_info('35.220.31.2') # GCP(Google Cloud Platform) Range
#search_ip_info('13.65.25.19') # Microsoft Azure Range