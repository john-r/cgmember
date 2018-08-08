Feature: Transact
AS a member
I WANT to transfer rCredits to or from another member (acting on their own behalf)
SO I can buy and sell stuff.
 We will eventually need variants or separate feature files for neighbor (member of different community within the region) to member, etc.
 And foreigner (member on a different server) to member, etc.

Setup:
  Given members:
  | id   | fullName | address | city  | state  | zip | country | postalAddr | rebate | flags      |*
  | .ZZA | Abe One  | 1 A St. | Atown | Alaska | 01000      | US      | 1 A, A, AK |  5 | ok,confirmed         |
  | .ZZB | Bea Two  | 2 B St. | Btown | Utah   | 02000      | US      | 2 B, B, UT | 10 | ok,confirmed         |
  | .ZZC | Our Pub  | 3 C St. | Ctown | Cher   |            | France  | 3 C, C, FR | 10 | ok,confirmed,co      |
  And relations:
  | main | agent | permission |*
  | .ZZA | .ZZB  | buy        |
  | .ZZB | .ZZA  | read       |
  | .ZZC | .ZZB  | buy        |
  | .ZZC | .ZZA  | sell       |
  And transactions: 
  | xid | created   | type   | amount | from | to   | purpose | taking |*
  |   1 | %today-6m | signup |    250 | ctty | .ZZA | signup  | 0      |
  |   2 | %today-6m | signup |    250 | ctty | .ZZB | signup  | 0      |
  |   3 | %today-6m | signup |    250 | ctty | .ZZC | signup  | 0      |
  Then balances:
  | id   | balance | rewards |*
  | .ZZA |       0 |     250 |
  | .ZZB |       0 |     250 |
  | .ZZC |       0 |     250 |

# (rightly fails, so do this in a separate feature) Variants: with/without an agent
#  | ".ZZA" | # member to member (pro se) |
#  | ".ZZA" | # agent to member           |

Scenario: A member asks to charge another member for goods
  When member ".ZZA" completes form "charge" with values:
  | op     | who     | amount | goods | purpose |*
  | charge | Bea Two | 100    | %FOR_GOODS     | labor   |
  Then we show "confirm charge" with subs:
  | amount | otherName | why                |*
  | $100   | Bea Two   | goods and services |

Scenario: A member confirms request to charge another member
  When member ".ZZA" confirms form "charge" with values:
  | op     | who     | amount | goods | purpose |*
  | charge | Bea Two | 100    | %FOR_GOODS     | labor   |
  Then we say "status": "report tx|for why|balance unchanged" with subs:
  | did     | otherName | amount | why                |*
  | charged | Bea Two   | $100   | goods and services |
  And we message "new invoice" to member ".ZZB" with subs:
  | otherName | amount | purpose |*
  | Abe One   | $100   | labor   |
  And invoices:
  | nvid | created | status      | amount | from | to  | for   |*
  |    1 | %today  | %TX_PENDING |    100 | .ZZB  | .ZZA | labor |
  And balances:
  | id   | balance | rewards |*
  | .ZZA |       0 |     250 |
  | .ZZB |       0 |     250 |
  | .ZZC |       0 |     250 |

Scenario: A member asks to pay another member for goods
  When member ".ZZA" completes form "pay" with values:
  | op  | who     | amount | goods | purpose |*
  | pay | Bea Two | 100    | %FOR_GOODS     | labor   |
  Then we show "confirm payment" with subs:
  | amount | otherName | why                |*
  | $100   | Bea Two   | goods and services |

Scenario: A member asks to pay another member for loan/reimbursement
  When member ".ZZA" completes form "pay" with values:
  | op  | who     | amount | goods | purpose |*
  | pay | Bea Two | 100    | %FOR_NONGOODS | loan    |
  Then we show "confirm payment" with subs:
  | amount | otherName | why                     |*
  | $100   | Bea Two   | loan/reimbursement/etc. |
  
Scenario: A member confirms request to pay another member
  When member ".ZZA" confirms form "pay" with values:
  | op  | who     | amount | goods | purpose |*
  | pay | Bea Two | 100    | %FOR_GOODS     | labor   |
  Then we say "status": "report tx|for why|the reward" with subs:
  | did    | otherName | amount | why                | rewardAmount |*
  | paid   | Bea Two   | $100   | goods and services | $5           |
  And we notice "new payment|reward other" to member ".ZZB" with subs:
  | created | fullName | otherName | amount | payeePurpose | otherRewardType | otherRewardAmount |*
  | %today  | Bea Two  | Abe One    | $100   | labor        | reward          |               $10 |
  And transactions:
  | xid | created | type     | amount | rebate | bonus | from  | to   | purpose      | taking |*
  |   4 | %today  | transfer |    100 |      5 |    10 | .ZZA  | .ZZB | labor        | 0      |
  And balances:
  | id   | balance | rewards |*
  | .ZZA |    -100 |     255 |
  | .ZZB |     100 |     260 |
  | .ZZC |       0 |     250 |
Scenario: A member confirms request to pay another member a lot
  Given balances:
  | id   | balance       |*
  | .ZZB | %R_MAX_AMOUNT |
  When member ".ZZB" confirms form "pay" with values:
  | op  | who     | amount        | goods | purpose |*
  | pay | Our Pub | %R_MAX_AMOUNT | %FOR_GOODS     | food    |
  Then transactions:
  | xid | created | type     | amount        | payerReward   | payeeReward   | from  | to   | purpose      | taking |*
  |   4 | %today  | transfer | %R_MAX_AMOUNT | %R_MAX_REBATE | %R_MAX_REBATE | .ZZB  | .ZZC | food         | 0      |
  
Scenario: A member confirms request to pay a member company
  Given next DO code is "whatever"
  When member ".ZZA" confirms form "pay" with values:
  | op  | who     | amount | goods | purpose |*
  | pay | Our Pub | 100    | %FOR_GOODS     | stuff   |
  Then we say "status": "report tx|for why|the reward" with subs:
  | did    | otherName | amount | why                | rewardAmount |*
  | paid   | Our Pub   | $100   | goods and services | $5           |
  And we notice "new payment linked|reward other" to member ".ZZC" with subs:
  | created | fullName | otherName | amount | payeePurpose | otherRewardType | otherRewardAmount | aPayLink |*
  | %today  | Our Pub  | Abe One   | $100 | stuff | reward | $10 | ? |
  And that "notice" has link results:
  | ~name | Abe One |
  | ~postalAddr | 1 A, A, AK |
  | Physical address: | 1 A St., Atown, AK 01000 |
  And transactions:
  | xid | created | type     | amount | payerReward | payeeReward | from  | to   | purpose      | taking |*
  |   4 | %today  | transfer |    100 |           5 |          10 | .ZZA  | .ZZC | stuff        | 0      |
  And balances:
  | id   | balance | rewards |*
  | .ZZA |    -100 |     255 |
  | .ZZB |       0 |     250 |
  | .ZZC |     100 |     260 |

#NO. Duplicates are never flagged on web interface.
#Scenario: A member confirms request to pay the same member the same amount
#  Given member ".ZZA" confirms form "pay" with values:
#  | op  | who     | amount | goods | purpose |*
#  | pay | Bea Two | 100    | %FOR_GOODS     | labor   |  
#  When member ".ZZA" confirms form "pay" with values:
#  | op  | who     | amount | goods | purpose |*
#  | pay | Bea Two | 100    | %FOR_GOODS     | labor   |
#  Then we say "error": "duplicate transaction" with subs:
#  | op   |*
#  | paid |
  
#Scenario: A member confirms request to charge the same member the same amount
#  Given member ".ZZA" confirms form "charge" with values:
#  | op     | who     | amount | goods | purpose |*
#  | charge | Bea Two | 100    | %FOR_GOODS     | labor   |  
#  When member ".ZZA" confirms form "charge" with values:
#  | op     | who     | amount | goods | purpose |*
#  | charge | Bea Two | 100    | %FOR_GOODS     | labor   |
#  Then we say "error": "duplicate transaction" with subs:
#  | op      |*
#  | charged |

Scenario: A member leaves goods blank
  Given member ".ZZA" confirms form "pay" with values:
  | op  | who     | amount | goods | purpose |*
  | pay | Bea Two | 100    |       | labor   |  
  Then we say "error": "required field" with subs:
  | field |*
  | "For" |

Skip  
Scenario: A member asks to charge another member before making an rCard purchase
  Given member ".ZZA" has no photo ID recorded
  When member ".ZZA" completes form "charge" with values:
  | op     | who     | amount | goods | purpose |*
  | charge | Bea Two | 100    | %FOR_GOODS     | labor   |
  Then we say "error": "no photoid"

Scenario: A member asks to charge another member before the other has made an rCard purchase
  Given member ".ZZB" has no photo ID recorded
  When member ".ZZA" completes form "charge" with values:
  | op     | who     | amount | goods | purpose |*
  | charge | Bea Two | 100    | %FOR_GOODS     | labor   |
  Then we say "error": "other no photoid" with subs:
  | who     |*
  | Bea Two |
  
Scenario: A member confirms request to pay before making a Common Good Card purchase
  Given member ".ZZA" confirms form "pay" with values:
  | op  | who     | amount | goods      | purpose |*
  | pay | Bea Two | 100    | %FOR_GOODS | labor   |  
  Then we say "error": "first at home"
  
Resume
Skip (not sure about this feature)
Scenario: A member asks to pay another member before making an rCard purchase
  Given member ".ZZA" has no photo ID recorded
  When member ".ZZA" completes form "pay" with values:
  | op  | who     | amount | goods | purpose |*
  | pay | Bea Two | 100    | %FOR_GOODS     | labor   |
  Then we say "error": "no photoid"
  
Scenario: A member asks to pay another member before the other has made an rCard purchase
  Given member ".ZZB" has no photo ID recorded
  When member ".ZZA" completes form "pay" with values:
  | op  | who     | amount | goods | purpose |*
  | pay | Bea Two | 100    | %FOR_GOODS     | labor   |
  Then we say "error": "other no photoid" with subs:
  | who     |*
  | Bea Two |
Resume
