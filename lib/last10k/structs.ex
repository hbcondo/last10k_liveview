defmodule Last10k.LatestFilings do
  @moduledoc """
  Collection of Filing objects
  """
  defstruct [
    count: 0,
    lastUpdated: NaiveDateTime.local_now(),
    filings: []
  ]
end

defmodule Last10k.Filing do
  @moduledoc """
  Filing object
  """
  defstruct [
    :id,
    :cik,
    :accessionNumber,
    :company,
    :reportingType,
    :formType,
    :filingDate,
    :acceptanceDate,
    :url_html,
    :url_text,
    :age,
    items: []
  ]
end
