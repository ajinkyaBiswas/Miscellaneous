#!/usr/bin/env python
__author__ = "Ajinkya Biswas"
__copyright__ = "Copyright 2024, The Sunday Project"
__credits__ = ["Ajinkya Biswas"]
__license__ = "OPEN"
__version__ = "0.1.1"
__maintainer__ = "Ajinkya Biswas"
__email__ = "biswas.ajinkya@gmail.com"
__status__ = "Beta"

# This script takes a bill details as input
# This script takes members and dates as inputs
# Then calculate bills among members

from datetime import date, timedelta, datetime
import pandas as pd

# Take bill details >> Bill Name, Bill Amount, Bill From Date, Bill To Date
print("Let's add the bill. You will need to enter bill amount, start date, end date.")

bill_name = input("Enter Bill Name. Example: Electricity, Water etc.:")
bill_amount = float(input("Enter Bill Amount: Example: 100:"))
bill_start_date = input("Enter Bill Start Date in YYYY-MM-DD format:")
bill_start_date = datetime.strptime(bill_start_date, '%Y-%m-%d').date()
bill_end_date = input("Enter Bill End Date in YYYY-MM-DD format:")
bill_end_date = datetime.strptime(bill_end_date, '%Y-%m-%d').date()

# Take member details >> Name, Start Date, End date

members = list()
add_another_member = 'Y'
member_num = 1
print("Let's add the members. You will need to add members' names, start dates and end dates ")
while add_another_member.upper() == 'Y':
    member_name = input(f"Enter Member_{member_num}'s Name:")
    member_start_date = input(f"Enter Member{member_num}'s Start Date in YYYY-MM-DD format:")
    member_start_date = datetime.strptime(member_start_date, '%Y-%m-%d').date()
    member_end_date = input(f"Enter Member{member_num}'s End Date in YYYY-MM-DD format:")
    member_end_date = datetime.strptime(member_end_date, '%Y-%m-%d').date()

    member = dict()
    member['name'] = member_name
    member['start_date'] = member_start_date
    member['end_date'] = member_end_date
    member['total'] = 0

    members.append(member)

    member_num += 1
    add_another_member = input("If you want to add another member, Type Y. If you have completed adding ALL members, "
                               "Type N:")


# Calculate
# Calculate per day amount
def daterange(start_date: date, end_date: date):
    days = int((end_date - start_date).days)
    for n in range(days+1):
        yield start_date + timedelta(n)


summary = dict()
summary['name'] = 'Total'
summary['start_date'] = str(bill_start_date)
summary['end_date'] = str(bill_end_date)
summary['total'] = bill_amount

for single_date in daterange(bill_start_date, bill_end_date):
    per_day_amount = bill_amount / (int((bill_end_date - bill_start_date).days)+1)
    summary[(single_date.strftime("%Y-%m-%d"))] = per_day_amount

    # print(single_date)

    number_of_members_has_share = 0
    for member in members:
        # Check if member has a share on that date or not
        # print(member['name'])
        if member['start_date'] <= single_date <= member['end_date']:
            # print("PAY UP!")
            number_of_members_has_share += 1
            member[(single_date.strftime("%Y-%m-%d"))] = -1
        else:
            # print("FREE TO GO!")
            member[(single_date.strftime("%Y-%m-%d"))] = 0

    share_per_member_on_this_date = per_day_amount / number_of_members_has_share

    # Update -1 with the share_per_member_on_this_date
    for member in members:
        if member[(single_date.strftime("%Y-%m-%d"))] == -1:
            member['total'] += share_per_member_on_this_date
            member[(single_date.strftime("%Y-%m-%d"))] = share_per_member_on_this_date

print('#' * (len(' SUMMARY ') + 2))
print('#', 'SUMMARY', '#')
print('#' * (len(' SUMMARY ') + 2))

print('Bill:', bill_name)
print('Total Bill Amount:', bill_amount)
print('Bill Start Date:', bill_start_date)
print('Bill End Date:', bill_end_date)
print('Total Bill days:', int((bill_end_date - bill_start_date).days) + 1, '\n')

for member in members:
    print(member['name'], 'has stayed', int((member['end_date'] - member['start_date']).days) + 1, 'days. \
    \tStarting from', str(member['start_date']), 'till', str(member['end_date']))
    print(member['name'], "'s share is", member['total'], '\n')

print('-' * 10)
print('Details')
print('-' * 10)
#  just format date ...there is probably better way above to do this
for member in members:
    member['start_date'] = str(member['start_date'])
    member['end_date'] = str(member['end_date'])
# print(summary)
# for member in members:
    # print(member)

members.append(summary)
df = pd.DataFrame(members)
df.to_csv(f'{bill_name}_{bill_start_date}_{bill_end_date}.csv', mode='w+')
print(df)
