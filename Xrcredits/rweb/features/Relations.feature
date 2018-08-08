Feature: Relations
AS a member
I WANT to manage my account's relations with other rCredits accounts
SO I can buy and sell stuff on behalf of other accounts, and they on mine.

Setup:
  Given members:
  | id   | fullName   | acctType    | flags      |*
  | .ZZA | Abe One    | personal    | ok         |
  | .ZZB | Bea Two    | personal    | ok         |
  | .ZZC | Corner Pub | corporation | ok,co      |
  | .ZZD | Dee Four   | personal    | ok         |
  And transactions: 
  | xid | created   | type       | amount | from      | to   | purpose | taking |*
  |   1 | %today-6m | %TX_SIGNUP |    250 | community | .ZZA | signup  | 0      |
  |   2 | %today-6m | %TX_SIGNUP |    250 | community | .ZZB | signup  | 0      |
  |   3 | %today-6m | %TX_SIGNUP |    250 | community | .ZZC | signup  | 0      |
  Then balances:
  | id        | balance | rewards |*
  | .ZZA      |       0 |     250 |
  | .ZZB      |       0 |     250 |
  | .ZZC      |       0 |     250 |

Scenario: Member has an employee, confirmed
  Given relations:
  | main | agent | permission   | employee | isOwner | draw |*
  | .ZZA | .ZZD  | scan         | 1          | 1       | 0    |
  When member ".ZZA" visits page "settings/relations"
  Then we show "Relations" with:
  | other      | Draw | My employee? | Family? | Permission |~requests      |
  | Dee Four   | No   | Yes          | Yes     | %can_scan  | -- |

Scenario: Member has an employee, unconfirmed
  Given relations:
  | main | agent | permission | employee | isOwner |*
  | .ZZA | .ZZD  | refund     | 1          | 0       |
  When member ".ZZA" visits page "settings/relations"
  Then we show "Relations" with:
  | other      | My employee? | Family? | Permission  |~requests      |
  | Dee Four   | Yes          | No      | %can_refund | --       |

Scenario: Member has a relation with a contractor
  Given relations:
  | main | agent | permission | employee | isOwner |*
  | .ZZA | .ZZB  | buy        | 0          | 0        |
  When member ".ZZA" visits page "settings/relations"
  Then we show "Relations" with:
  | other      | My employee? | Family? | Permission |~requests      |
  | Bea Two    | No           | No      | %can_buy   | --            |
  
Scenario: Member has an employee, claimed
  Given relations:
  | main | agent | permission   | employee | isOwner |*
  | .ZZA | .ZZD  | sell         | 0          | 0       |
  When member ".ZZA" visits page "settings/relations"
  Then we show "Relations" with:
  | other      | My employee? | Family? | Permission |~requests      |
  | Dee Four   | No           | No      | %can_sell  | -- |
  
Scenario: Employee can only read
  Given relations:
  | main | agent | permission | employee | isOwner |*
  | .ZZA | .ZZD  | read       | 1          | 1       |
  When member ".ZZA" visits page "settings/relations"
  Then we show "Relations" with:
  | other      | My employee? | Family? | Permission |~requests      |
  | Dee Four   | Yes          | Yes     | %can_read  | --       |
  
Scenario: Member has an employer
  Given relations:
  | main | agent | permission   | employee | isOwner |*
  | .ZZB | .ZZA  | sell         | 1          | 1        |
  When member ".ZZA" visits page "settings/relations"
  Then we show "Relations" with:
  | other      | My employee? | Family? | Permission |~requests      |
  And without:
  | Bea Two |
  
Scenario: Member has access to employee account
  Given relations:
  | main | agent | permission | employee | isOwner |*
  | .ZZA | .ZZD  |            | 1          | 1        |
  | .ZZD | .ZZA  | sell       | 0          | 0        |
  When member ".ZZA" visits page "settings/relations"
  Then we show "Relations" with:
  | other      | My employee? | Family? | Permission |~requests      |
  | Dee Four   | Yes          | Yes     | %can_none  | --            |
  When member ".ZZD" visits page "settings/relations"
  Then we show "Relations" with:
  | other      | My employee? | Family? | Permission |~requests      |
  | Abe One    | No           | No      | %can_sell  | -- |

Scenario: Member company has relations
  Given relations:
  | main | agent | num | permission | employee | isOwner |*
  | .ZZC | .ZZA  |   1 | manage     | 1          | 1        |
  When member "C:A" visits page "settings/relations"
  Then we show "Relations" with:
  | other   | My employee? | Owns | Permission     |~requests      |
  | Abe One | Yes          | Yes  | manage account | request Common Good Card |
  When member ".ZZA" visits page "settings/relations"
  Then we show "Relations" with:
  | other      | My employee? | Family? | Permission   |~requests      |
  And without:
  | Corner Pub |

Scenario: It's complicated
  Given relations:
  | main | agent | num | permission | employee | isOwner |*
  | .ZZA | .ZZD  |   0 | manage     | 1        | 1       |
  | .ZZD | .ZZA  |   0 |            | 0        | 0       |
  | .ZZA | .ZZC  |   0 | buy        | 0        | 0       |
  | .ZZC | .ZZA  |   1 | scan       | 1        | 0       |
  | .ZZA | .ZZB  |   0 | sell       | 1        | 1       |
  | .ZZB | .ZZA  |   0 |            | 1        | 0       |
  When member ".ZZA" visits page "settings/relations"
  Then we show "Relations" with:
  | other      | My employee? | Family? | Permission  |~requests      |
  | Bea Two    | Yes          | Yes     | %can_sell   | -- |
  | Corner Pub | --           | No      | --          | --       |
  | Dee Four   | Yes          | Yes     | %can_manage | -- |
  When member ".ZZB" visits page "settings/relations"
  Then we show "Relations" with:
  | other   | My employee? | Family? | Permission |~requests      |
  | Abe One | Yes          | No      | %can_none  | --            |
  When member ".ZZD" visits page "settings/relations"
  Then we show "Relations" with:
  | other   | My employee? | Family? | Permission |~requests      |
  | Abe One | No           | No      | %can_none  | --            |
  And with:
  |~Header  |
  | Family? |
  When member "C:A" visits page "settings/relations"
  Then we show "Relations" with:
  | other   | My employee? | Owns | Permission  |~requests      |
  | Abe One | Yes          | No   | %can_scan | request Cashier Card |

Scenario: A member adds a relation
# This test fails (but works fine). Dunno why.
  When member ".ZZA" completes relations form with values:
  | newPerson |*
  | Bea Two   |
  Then we say "status": "report new relation" with subs:
  | who     |*
  | Bea Two |
  And we show "Relations" with:
  | other      | Draw | My employee? | Family? | Permission |~requests      |
  | Bea Two    | No   | No           | No      | %can_none  | --            |

Scenario: A member tries to add a relation with self
  When member ".ZZA" completes relations form with values:
  | newPerson |*
  | Abe One   |
  Then we say "error": "no self-relation"

Scenario: A member tries to add a relation again
  Given relations:
  | main | agent | permission | employee | isOwner |*
  | .ZZA | .ZZB  | scan       | 1        | 1       |
  When member ".ZZA" completes relations form with values:
  | newPerson |*
  | Bea Two   |
  Then we say "error": "already related"
  