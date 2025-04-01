defmodule StartupGame.CaseStudies.Frank do
  @moduledoc """
  A case study for Frank
  """

  alias StartupGame.CaseStudies.CaseStudy

  @spec case_study() :: CaseStudy.t()
  def case_study do
    %{
      user: %{
        name: "heyitscharlie"
      },
      company: "Frank",
      description: "Frank is a platform that helps students apply for federal financial aid.",
      rounds: rounds(),
      status: :completed,
      exit_type: :acquisition,
      exit_value: Decimal.new(175_000_000),
      founder_return: Decimal.new(175_000_000)
    }
  end

  @spec rounds() :: [CaseStudy.round()]
  defp rounds do
    [
      %{
        situation:
          "You’re a fresh college grad with a big idea: simplifying student financial aid. The government process is confusing, so there’s an opportunity for disruption. What do you do?",
        response:
          "Create a website that looks official enough to make students think they’re applying for FAFSA through us. Also, call it “Frank” to sound trustworthy.",
        outcome: "Clever branding. "
      },
      %{
        situation:
          "Unfortunately, the U.S. Department of Education is not amused and demands you clarify that Frank isn’t actually affiliated with the government.",
        response:
          "Fine, I’ll tweak the wording. But I’ll keep it just ambiguous enough to still trick people.",
        outcome: "Nice. You avoid major consequences… for now."
      },
      %{
        situation:
          "It’s 2017. Your company is growing fast, but the government is sniffing around. Regulators think you’re misleading students. What’s your move?",
        response: "Ignore it. Tech bros always say, \"Move fast and break things,\" right?",
        outcome: "Bold strategy. You get a warning from the FTC."
      },
      %{
        situation:
          "2020 rolls around. Lawmakers are calling for an investigation, and the FTC is eyeing you suspiciously. What do you do?",
        response:
          "Still ignoring it. But let’s make the company look even bigger so we can sell it for a fortune.",
        outcome: "Risky but on brand."
      },
      %{
        situation:
          "JPMorgan Chase, a financial giant with more money than common sense, is interested in acquiring Frank. They love the idea of 4.25 million users. What do you say?",
        response: "“Oh, absolutely, we have at least 4 million users.”",
        outcome: "You actually only have 300,000 users..."
      },
      %{
        situation: "So about those 4 million users...",
        response:
          "No problem—I’ll invent the rest. Hire a data scientist, generate a bunch of fake accounts, and hand over a spreadsheet full of nonsense.",
        outcome: "JPMorgan barely checks and gives you $175 million."
      },
      %{
        situation:
          "JPMorgan starts sending marketing emails to 400,000 of your “users.” 70% of them bounce back. Now they’re very, very suspicious. What do you do?",
        response: "Uh… blame an intern?",
        outcome: "They don’t buy it. JPMorgan sues you for fraud."
      },
      %{
        situation:
          "April 2023. You are arrested for wire fraud, bank fraud, and conspiracy. What’s your defense?",
        response: "“I was just a scrappy entrepreneur trying to innovate in financial aid!”",
        outcome: "The court isn’t convinced."
      },
      %{
        situation: "Any other ideas?",
        response: "Okay… then I’ll throw my expensive lawyers at them?",
        outcome:
          "The DOJ, SEC, and FBI all say, “Nope.” Your bail is set, and you’re facing up to 30 years."
      },
      %{
        situation: "Things are looking grim. What do you do?",
        response: "Can I pivot this into a TED Talk about resilience?",
        outcome: "Only from prison."
      },
      %{
        situation: "2025. Your trial is over. You are convicted. Any final words?",
        response: "“I should have just started a crypto exchange instead.”",
        outcome: "Maybe next time."
      }
    ]
  end
end
