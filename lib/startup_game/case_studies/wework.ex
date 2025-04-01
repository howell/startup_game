defmodule StartupGame.CaseStudies.WeWork do
  @moduledoc """
  A case study for WeWork
  """

  alias StartupGame.CaseStudies.CaseStudy

  @spec case_study() :: CaseStudy.t()
  def case_study do
    %{
      user: %{
        name: "adamnn"
      },
      company: "WeWork",
      description:
        "WeWork is a coworking space company that allows people to work together in a shared space.",
      rounds: rounds(),
      status: :completed,
      exit_type: :acquisition,
      exit_value: Decimal.new(350_000_000),
      founder_return: Decimal.new(700_000_000)
    }
  end

  @spec rounds() :: [CaseStudy.round()]
  defp rounds do
    [
      %{
        situation:
          "You’re Adam Neumann, a smooth-talking entrepreneur in NYC. You and Miguel McKelvey just launched WeWork, a company that rents office space and subleases it to freelancers. You have zero tech, zero innovation, and a whole lot of confidence. What do you do?",
        response:
          "We don’t just rent office space. We sell a vision! Throw in words like ‘community,’ ‘conscious capitalism,’ and ‘changing the world’ until investors forget we’re just a fancy landlord.",
        outcome:
          "Investors are dazzled. You secure millions in funding and open your first location in SoHo. Somehow, people think you’re a tech founder now."
      },
      %{
        situation:
          "WeWork is growing fast, but so are your expenses. You need more cash. What’s the move?",
        response:
          "Easy. Blitzscale! Open as many locations as possible, burn cash like it’s free, and just keep raising money. Profits? Who needs those?",
        outcome:
          "You successfully convince investors that \"growth\" is more important than profits. Valuation soars to $1.5 billion, and nobody asks too many questions. Yet."
      },
      %{
        situation:
          "You’re now the biggest name in co-working. SoftBank just handed you a casual $4.4 billion because they think you’re the next Steve Jobs. What do you do?",
        response:
          "Time to expand the We brand! WeWork, WeLive (co-living), WeGrow (schools), WeBuy-Jets-And-Party…",
        outcome:
          "You buy a $60 million private jet, lease buildings from yourself, and trademark the word ‘We’—then sell it back to your company for $5.9 million. Somehow, no one stops you."
      },
      %{
        situation:
          "SoftBank just pushed your valuation to $47 billion. You’re going public! But that means opening your books to investors. What’s your strategy?",
        response:
          "Tell them WeWork isn’t a real estate company—it’s a tech company! And throw in some spiritual nonsense about ‘elevating the world’s consciousness’ for good measure.",
        outcome:
          "Wall Street isn’t buying it. Your IPO filing reveals $1.6 billion in annual losses, a bizarre corporate structure, and the fact that you… uh… rented properties to yourself? Investors panic. Valuation crashes from $47 billion to under $10 billion in days."
      },
      %{
        situation:
          "The IPO is dead. Investors are furious. Your board is planning a coup. What do you do?",
        response:
          "Demand a $1.7 billion golden parachute to leave. If I’m going down, I’m going down rich!",
        outcome:
          "SoftBank actually agrees to pay you off. You resign as CEO, and your reputation is ruined… but your bank account isn’t. You walk away a billionaire."
      },
      %{
        situation:
          "WeWork limps along, struggling under its own weight. By 2023, it files for bankruptcy. You’re officially the poster child for Silicon Valley fraud. What now?",
        response:
          "Do it again. I’m launching Flow—a ‘revolutionary’ real estate startup that’s just… luxury apartments with a fancy logo. Also, let’s call it ‘tech’ again.",
        outcome:
          "Venture capitalists still haven’t learned. Andreessen Horowitz gives you $350 million for Flow. You win at Silicon Valley Hustle—again."
      }
    ]
  end
end
