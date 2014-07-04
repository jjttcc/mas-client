# Constants used for TIME_PERIOD_TYPEs
module TimePeriodTypeConstants

  public

  YEARLY         = "yearly"
  # Name of the yearly time period type

  QUARTERLY      = "quarterly"
  # Name of the quarterly time period type

  MONTHLY        = "monthly"
  # etc...

  WEEKLY         = "weekly"

  DAILY          = "daily"

  ONE_MINUTE     = "1-minute"

  TWO_MINUTE     = "2-minute"

  FIVE_MINUTE    = "5-minute"

  TEN_MINUTE     = "10-minute"

  FIFTEEN_MINUTE = "15-minute"

  TWENTY_MINUTE  = "20-minute"

  THIRTY_MINUTE  = "30-minute"

  HOURLY         = "hourly"

  INVALID        = "Invalid type"
  # Name of invalid period types

  @@period_types = [DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY,
                    ONE_MINUTE, TWO_MINUTE, FIVE_MINUTE, TEN_MINUTE,
                    FIFTEEN_MINUTE, TWENTY_MINUTE, THIRTY_MINUTE, HOURLY]

end
