defmodule StartupGame.Engine.LLM.PromptExamples do
  @moduledoc """
  Provides example scenarios and outcomes for LLM prompts.
  These examples are used for few-shot prompting to guide the model's responses.
  """

  @type scenario_example :: %{
          description: String.t(),
          narrative: String.t(),
          json: map()
        }

  @type outcome_example :: %{
          description: String.t(),
          narrative: String.t(),
          json: map()
        }

  @type ownership_change :: %{
          entity_name: String.t(),
          previous_percentage: integer(),
          new_percentage: integer()
        }

  @doc """
  Returns formatted scenario examples for use in system prompts.
  """
  @spec scenario_examples() :: [scenario_example()]
  def scenario_examples do
    [
      %{
        description: "Funding opportunity example",
        narrative: """
        You've been running your startup for six months now, and while the product is showing promise, your runway is starting to look shorter than you'd like. The good news is that your networking efforts have paid off – a well-known venture capital firm, Horizon Ventures, has expressed interest in your company.

        They've offered to invest $500,000 for a 15% stake in your company, which would value your startup at approximately $3.3 million. This investment would extend your runway significantly and allow you to hire much-needed talent to accelerate product development.

        However, you've also heard through your network that another VC firm might be interested and could potentially offer better terms. Pursuing that lead would delay funding by at least two months, during which time you'll continue burning through your limited cash reserves.

        What do you want to do regarding this investment opportunity?
        """,
        json: %{
          "id" => "funding_round_seed",
          "type" => "funding"
        }
      },
      %{
        description: "Hiring challenge example",
        narrative: """
        Your Chief Technology Officer has just resigned unexpectedly, citing a family emergency that requires them to relocate. This couldn't come at a worse time – you're three weeks away from launching your product's 2.0 version, which includes several major architectural changes they were leading.

        You have three potential options to consider:

        1. Promote your senior developer to interim CTO. They know the codebase well but have no experience managing a team or making high-level technical decisions.

        2. Delay the launch and spend time recruiting an experienced CTO from outside the company, which could take 1-3 months and require a competitive compensation package.

        3. Bring in a technical consultant on a short-term contract to help complete the launch, then take your time finding a permanent CTO afterward.

        Each choice comes with its own risks and financial implications. How do you want to handle this sudden leadership gap in your technical team?
        """,
        json: %{
          "id" => "cto_departure",
          "type" => "hiring"
        }
      },
      %{
        description: "Legal issue example",
        narrative: """
        Your legal team has just informed you of a cease and desist letter from TechGiant, Inc., a major player in your industry. They claim that a feature in your product infringes on one of their patents. The letter demands that you remove the feature immediately or face potential legal action.

        The feature in question is popular with your users and differentiates your product from competitors. Your legal team estimates that:

        1. Fighting this claim could cost $100,000-$250,000 in legal fees with no guarantee of winning
        2. Removing the feature would be technically straightforward but might affect user retention
        3. There might be a way to redesign the feature to work differently while providing similar functionality

        This comes at a time when you were planning to raise your next funding round, and legal troubles could significantly impact investor interest.

        How do you want to respond to this patent infringement claim?
        """,
        json: %{
          "id" => "patent_infringement",
          "type" => "legal"
        }
      }
    ]
  end

  @doc """
  Returns formatted outcome examples for use in system prompts.
  """
  @spec outcome_examples() :: [outcome_example()]
  def outcome_examples do
    [
      %{
        description: "Positive funding outcome",
        narrative: """
        Your decision to accept Horizon Ventures' investment proves to be timely and strategic. Within three weeks, the deal is finalized, and $500,000 is wired to your company account. The due diligence process goes smoothly, with the investors impressed by your organized documentation and clear business strategy.

        The capital injection immediately relieves your cash flow concerns. With a comfortable runway extension, you can now focus on strategic growth rather than short-term survival. You hire three key engineers who quickly strengthen your development team, accelerating your product roadmap by approximately two months.

        Beyond the money, Horizon Ventures introduces you to their network of industry contacts. Through these introductions, you secure a pilot program with a mid-sized enterprise client that could potentially become a significant revenue source in the next quarter.

        Your decision to accept the funding now rather than waiting has positioned your company for stronger growth, though you did have to give up 15% of your equity earlier than you might have in a perfect world.
        """,
        json: %{
          "cash_change" => 500_000,
          "burn_rate_change" => 30_000,
          "ownership_changes" => [
            %{
              "entity_name" => "Founder",
              "previous_percentage" => 100,
              "new_percentage" => 85
            },
            %{
              "entity_name" => "Horizon Ventures",
              "previous_percentage" => 0,
              "new_percentage" => 15
            }
          ],
          "exit_type" => "none"
        }
      },
      %{
        description: "Mixed hiring outcome",
        narrative: """
        You decide to promote your senior developer, Alex, to interim CTO with a promise to reassess in three months. Initially, this seems to be working well. Alex knows the codebase intimately and quickly organizes the team to continue work on the planned release.

        However, as the launch date approaches, challenges emerge. While Alex excels at coding, they struggle with the architectural decision-making required for the role. The team misses the original launch deadline by two weeks, and when the product finally launches, several critical bugs require emergency patches.

        User feedback is mixed – the new features are appreciated, but the initial instability damages confidence in your product. You lose approximately 5% of your user base but manage to stabilize the situation over the following month.

        Alex's performance reveals both strengths and limitations. They demonstrate exceptional dedication but acknowledge they need mentorship in strategic planning and team leadership. You agree to hire an experienced technical director to work alongside Alex, creating a more balanced leadership structure.

        This compromise increases your burn rate with the additional executive salary but prevents the much larger costs of a failed product launch or extended delay. The market perceives the eventual stability as a recovery, and you manage to retain most of your customers through transparent communication about the challenges and solutions.
        """,
        json: %{
          "cash_change" => -20_000,
          "burn_rate_change" => 15_000,
          "ownership_changes" => nil,
          "exit_type" => "none"
        }
      },
      %{
        description: "Negative legal outcome with exit",
        narrative: """
        You decide to fight the patent infringement claim, believing your innovation shouldn't be stifled by TechGiant's aggressive legal tactics. Initially, your stance is celebrated by your team and a vocal portion of your user base who see you as standing up to a corporate bully.

        Unfortunately, the reality of the legal battle proves far more challenging than anticipated. The case drags on for months, with legal costs quickly exceeding the higher-end estimates. Your attorneys discover that the patent in question, while potentially challengeable, is worded broadly enough that the litigation could continue for years.

        The ongoing legal battle creates several cascading problems:

        1. Your planned funding round collapses when three key investors withdraw, citing concerns about the unresolved legal issues
        2. The development team becomes demoralized as resources are diverted from product development to legal defense
        3. Your marketing team struggles to promote a product with an uncertain future

        After six months of mounting costs and dwindling cash reserves, a potential acquirer, SoftSolutions Inc., approaches with an offer. They're primarily interested in your engineering talent and customer base, and they have the legal resources to potentially resolve the patent dispute.

        Their offer values the company at significantly less than your previous funding round's valuation, but with bankruptcy looming as a real possibility, you reluctantly accept. The acquisition provides an exit, but not the one you had hoped for.
        """,
        json: %{
          "cash_change" => -350_000,
          "burn_rate_change" => 0,
          "ownership_changes" => nil,
          "exit_type" => "acquisition",
          "exit_value" => 1_200_000
        }
      }
    ]
  end

  @doc """
  Formats scenario examples for inclusion in the system prompt with XML-style tags.
  """
  @spec format_scenario_examples() :: String.t()
  def format_scenario_examples do
    scenario_examples()
    |> Enum.map_join("\n\n", fn example ->
      """
      <example>
      #{example.narrative}
      ---JSON DATA---
      #{Jason.encode!(example.json, pretty: true)}
      </example>
      """
    end)
  end

  @doc """
  Formats outcome examples for inclusion in the system prompt with XML-style tags.
  """
  @spec format_outcome_examples() :: String.t()
  def format_outcome_examples do
    outcome_examples()
    |> Enum.map_join("\n\n", fn example ->
      """
      <example>
      #{example.narrative}
      ---JSON DATA---
      #{Jason.encode!(example.json, pretty: true)}
      </example>
      """
    end)
  end
end
