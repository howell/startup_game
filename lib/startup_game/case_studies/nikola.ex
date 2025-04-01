defmodule StartupGame.CaseStudies.Nikola do
  @moduledoc """
  A case study for Nikola
  """

  alias StartupGame.CaseStudies.CaseStudy

  @spec case_study() :: CaseStudy.t()
  def case_study do
    %{
      user: %{
        name: "bigtrev"
      },
      company: "Nikola",
      description: "Nikola is a company that makes electric trucks.",
      rounds: rounds(),
      status: :completed,
      exit_type: :ipo,
      exit_value: Decimal.new(3_300_000_000),
      founder_return: Decimal.new(1_000_000_000)
    }
  end

  @spec rounds() :: [CaseStudy.round()]
  defp rounds do
    [
      %{
        situation:
          "You’re Trevor Milton, an ambitious entrepreneur with zero engineering expertise but infinite confidence. Tesla is making headlines with electric cars. What do you do?",
        response:
          "I start my own company, but instead of just EVs, I go for hydrogen-powered semi-trucks. Let’s call it Nikola—close enough to Tesla to confuse people.",
        outcome: "Clever branding! Investors are intrigued. What’s next?"
      },
      %{
        situation: "You need a product to sell the vision. What’s the plan?",
        response:
          "Announce the Nikola One, a futuristic semi-truck with a 1,000-mile range and hydrogen power. Post a flashy render and promise a revolution.",
        outcome: "Nice. No one asks if you actually have the technology. The hype builds."
      },
      %{
        situation: "People want to see the truck in action. Do you have a working prototype?",
        response:
          "Not exactly. But I can roll one down a hill and film it! We’ll say it’s moving under its own power.",
        outcome: "Investors eat it up. Your credibility skyrockets."
      },
      %{
        situation: "It’s 2019. You need a manufacturing facility. What’s the move?",
        response:
          "Buy land in Arizona and announce a factory capable of producing 50,000 trucks a year. Investors stay excited.",
        outcome: "Great! Just don’t actually build anything yet. Investors stay excited."
      },
      %{
        situation: "You need more funding. What’s your strategy?",
        response:
          "SPACs are hot! Merge with VectoIQ and take Nikola public. Instant billions! Investors believe you’re the next Elon Musk.",
        outcome:
          "Your stock price soars. At one point, Nikola is worth more than Ford. Investors believe you’re the next Elon Musk."
      },
      %{
        situation: "Big companies are taking notice. Any partnerships in mind?",
        response:
          "General Motors. I’ll announce the Nikola Badger pickup and have GM build it for us. GM agrees to take an 11% stake. Your credibility reaches new heights.",
        outcome: "GM agrees to take an 11% stake. Your credibility reaches new heights."
      },
      %{
        situation:
          "Uh-oh. A short-seller firm, Hindenburg Research, just published a report calling Nikola “an intricate fraud.” They exposed the rolling-truck trick. What’s your response?",
        response:
          "Call it a hit job and deny everything! Say we never technically claimed the truck was driving itself.",
        outcome: "The internet finds clips where you said exactly that. The stock tanks."
      },
      %{
        situation: "Investors are panicking. What do you do?",
        response: "Step down as CEO. That should calm everyone down.",
        outcome: "You resign, but Nikola’s stock keeps crashing. GM bails on the Badger deal."
      },
      %{
        situation: "The SEC and DOJ are investigating you for fraud. What’s your defense?",
        response: "I was just optimistic! That’s not illegal, right?",
        outcome: "The jury disagrees. You’re convicted of fraud in 2022."
      },
      %{
        situation: "It’s December 2023. Time for sentencing. Any final words?",
        response: "Nikola will still change the world!",
        outcome: "The judge gives you four years in prison."
      },
      %{
        situation:
          "Nikola is drowning in debt. The company files for bankruptcy in 2025. What do you do?",
        response: "Well, that sucks. At least I still have money, right?",
        outcome: "Actually, no. You owe millions in restitution."
      },
      %{
        situation: "Any last-ditch moves?",
        response: "Can I get a pardon?",
        outcome:
          "Surprise twist! In 2025, President Donald Trump pardons you, calling you a victim of “woke regulators.”"
      },
      %{
        situation: "So, what's next?",
        response: "Let’s gooo! Can I start another company?",
        outcome: "You can try, but the internet will never forget that truck rolling downhill."
      }
    ]
  end
end
