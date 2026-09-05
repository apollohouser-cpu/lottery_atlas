/// The approved, public-facing official resources used by Lottery Atlas.
///
/// Keeping these in one registry makes it straightforward to expand coverage
/// state by state without mixing official links with sample map activity.
class StateLotterySourceRegistry {
  StateLotterySourceRegistry._();

  static const Map<String, StateLotterySource> _sources = {
    'South Carolina': StateLotterySource(
      stateName: 'South Carolina',
      providerName: 'South Carolina Education Lottery',
      hasVerifiedSchedule: true,
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Current results, jackpots, and game information.',
          url: 'https://www.sceducationlottery.com/',
        ),
        StateLotteryResource(
          title: 'All South Carolina games',
          subtitle: 'Browse draw games, Scratch-Offs, rules, and prizes.',
          url: 'https://www.sceducationlottery.com/Games',
        ),
        StateLotteryResource(
          title: 'Drawing times and how to play',
          subtitle: 'Official schedules, rules, and claiming guidance.',
          url: 'https://www.sceducationlottery.com/Games/HowtoPlay',
        ),
        StateLotteryResource(
          title: 'Daily Scratch-Off winners',
          subtitle: 'Official daily totals for claimed Scratch-Off prizes.',
          url: 'https://www.sceducationlottery.com/Games/DailyInstantWinners',
        ),
        StateLotteryResource(
          title: 'Remaining Scratch-Off prizes',
          subtitle: 'Official estimates of remaining and unclaimed prizes.',
          url: 'https://www.sceducationlottery.com/Games/PrizesRemaining',
        ),
      ],
    ),
    'North Carolina': StateLotterySource(
      stateName: 'North Carolina',
      providerName: 'North Carolina Education Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Current results, jackpot estimates, and game information.',
          url: 'https://nclottery.com/',
        ),
        StateLotteryResource(
          title: 'Draw games',
          subtitle: 'Official draw-game details and current winning numbers.',
          url: 'https://nclottery.com/draw-games',
        ),
        StateLotteryResource(
          title: 'Powerball winner claims',
          subtitle:
              'Official claimed-winning-ticket list, updated weekly for prizes of \$5,000 and above.',
          url: 'https://nclottery.com/WinnersAll?g=PB&p=1',
        ),
        StateLotteryResource(
          title: 'Mega Millions winner claims',
          subtitle:
              'Official claimed-winning-ticket list, updated weekly for prizes of \$5,000 and above.',
          url: 'https://nclottery.com/WinnersAll?g=MM',
        ),
        StateLotteryResource(
          title: 'Cash 5 winner claims',
          subtitle:
              'Official claimed-winning-ticket list, including qualifying Cash 5 prizes.',
          url: 'https://nclottery.com/WinnersAll?g=C5&p=1',
        ),
        StateLotteryResource(
          title: 'Pick 4 winner claims',
          subtitle:
              'Official claimed-winning-ticket list, including qualifying Pick 4 prizes.',
          url: 'https://nclottery.com/WinnersAll?g=P4&p=1',
        ),
        StateLotteryResource(
          title: 'Scratch-Off games',
          subtitle: 'Official Scratch-Off game catalog and game details.',
          url: 'https://nclottery.com/scratch-off',
        ),
        StateLotteryResource(
          title: 'Remaining Scratch-Off prizes',
          subtitle: 'Official prize counts, updated daily by the NC Lottery.',
          url: 'https://nclottery.com/scratch-off-prizes-remaining',
        ),
      ],
    ),
    'Georgia': StateLotterySource(
      stateName: 'Georgia',
      providerName: 'Georgia Lottery Corporation',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official winning-number lookup and draw-game information.',
          url: 'https://mapi.galottery.com/en-us/winning-numbers.html',
        ),
        StateLotteryResource(
          title: 'Active Scratchers',
          subtitle: 'Official active Georgia Scratchers catalog.',
          url:
              'https://gas-origin2.galottery.com/en-us/games/scratchers/active-games.html',
        ),
        StateLotteryResource(
          title: 'Scratchers top prizes claimed',
          subtitle: 'Official record of claimed Scratchers top prizes.',
          url:
              'https://gas-origin2.galottery.com/en-us/games/scratchers/scratchers-top-prizes-claimed.html',
        ),
      ],
    ),
    'Florida': StateLotterySource(
      stateName: 'Florida',
      providerName: 'Florida Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Florida Lottery draw results.',
          url: 'https://floridalottery.com/games/winning-numbers',
        ),
        StateLotteryResource(
          title: 'Draw games',
          subtitle: 'Official draw-game information, schedules, and results.',
          url: 'https://floridalottery.com/games/draw-games',
        ),
        StateLotteryResource(
          title: 'Scratch-Off games',
          subtitle: 'Official Florida Scratch-Off catalog.',
          url: 'https://floridalottery.com/games/scratch-offs',
        ),
        StateLotteryResource(
          title: 'Top remaining prizes',
          subtitle: 'Official remaining top Scratch-Off prizes.',
          url:
              'https://floridalottery.com/games/scratch-offs/top-remaining-prizes',
        ),
      ],
    ),
    'Tennessee': StateLotterySource(
      stateName: 'Tennessee',
      providerName: 'Tennessee Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Tennessee Lottery winning-number center.',
          url: 'https://tnlottery.com/',
        ),
        StateLotteryResource(
          title: 'Daily Tennessee Jackpot',
          subtitle: 'Official Daily Tennessee Jackpot results.',
          url: 'https://tnlottery.com/winning-numbers/daily-tennessee-jackpot/',
        ),
        StateLotteryResource(
          title: 'New instant games',
          subtitle: 'Official new Tennessee instant-game catalog.',
          url: 'https://tnlottery.com/new-instant-games/',
        ),
        StateLotteryResource(
          title: 'Remaining prizes',
          subtitle: 'Official remaining prizes for Tennessee instant games.',
          url: 'https://tnlottery.com/remaining-prizes/',
        ),
      ],
    ),
    'Virginia': StateLotterySource(
      stateName: 'Virginia',
      providerName: 'Virginia Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Virginia Lottery winning numbers and draw times.',
          url: 'https://www.valottery.com/',
        ),
        StateLotteryResource(
          title: 'Scratchers',
          subtitle:
              'Official Virginia Scratcher games and current game details.',
          url: 'https://www.valottery.com/scratcher-search?view=0',
        ),
      ],
    ),
    'Kentucky': StateLotterySource(
      stateName: 'Kentucky',
      providerName: 'Kentucky Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Kentucky Lottery results and game information.',
          url: 'https://www.kylottery.com/',
        ),
        StateLotteryResource(
          title: 'Available Scratch-Off games',
          subtitle: 'Official Kentucky Scratch-Off catalog.',
          url:
              'https://www.kylottery.com/apps/scratch_offs/available_games.html',
        ),
        StateLotteryResource(
          title: 'Scratch-Off prizes remaining',
          subtitle: 'Official Kentucky Scratch-Off remaining-prize data.',
          url:
              'https://www.kylottery.com/apps/scratch_offs/prizes_remaining.html',
        ),
      ],
    ),
    'Maryland': StateLotterySource(
      stateName: 'Maryland',
      providerName: 'Maryland Lottery and Gaming',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Maryland Lottery results, jackpots, and games.',
          url: 'https://www.mdlottery.com/',
        ),
        StateLotteryResource(
          title: 'Scratch-Off games',
          subtitle: 'Official Maryland Scratch-Off games and prize details.',
          url: 'https://www.mdlottery.com/games/scratch-offs/',
        ),
        StateLotteryResource(
          title: 'Maryland winners',
          subtitle: 'Official Maryland Lottery winner information.',
          url: 'https://www.mdlottery.com/winners/',
        ),
      ],
    ),
    'Delaware': StateLotterySource(
      stateName: 'Delaware',
      providerName: 'Delaware Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Delaware Lottery results and game information.',
          url: 'https://www.delottery.com/',
        ),
        StateLotteryResource(
          title: 'Remaining instant-game prizes',
          subtitle: 'Official Delaware Lottery top-prize information.',
          url: 'https://www.delottery.com/Instant-Games/Top-Prizes-Remaining',
        ),
      ],
    ),
    'Pennsylvania': StateLotterySource(
      stateName: 'Pennsylvania',
      providerName: 'Pennsylvania Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official Pennsylvania Lottery',
          subtitle: 'Results, draw games, Scratch-Offs, and player resources.',
          url: 'https://www.palottery.com/',
        ),
        StateLotteryResource(
          title: 'Drawing schedule',
          subtitle: 'Official Pennsylvania Lottery draw-game schedule.',
          url:
              'https://www.palottery.pa.gov/PaLotteryWebSite/media/Page-Images/Game%20Guide/Game-Guide_2025.pdf',
        ),
        StateLotteryResource(
          title: 'Scratch-Off prizes remaining',
          subtitle:
              'Official Pennsylvania Lottery active games and prize counts.',
          url:
              'https://www.palottery.pa.gov/Scratch-Offs/Prizes-Remaining.aspx',
        ),
      ],
    ),
    'New Jersey': StateLotterySource(
      stateName: 'New Jersey',
      providerName: 'New Jersey Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official New Jersey Lottery',
          subtitle: 'Results, draw games, Scratch-Offs, and player resources.',
          url: 'https://www.njlottery.com/en-us/home.html',
        ),
      ],
    ),
    'New York': StateLotterySource(
      stateName: 'New York',
      providerName: 'New York Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official New York Lottery results and game information.',
          url: 'https://nylottery.ny.gov/',
        ),
        StateLotteryResource(
          title: 'Draw games and drawing times',
          subtitle: 'Official schedule for New York draw games.',
          url: 'https://nylottery.ny.gov/draw-games/',
        ),
        StateLotteryResource(
          title: 'Scratch-Off games',
          subtitle: 'Official New York Lottery Scratch-Off game catalog.',
          url: 'https://nylottery.ny.gov/scratch-off-games',
        ),
      ],
    ),
    'Maine': StateLotterySource(
      stateName: 'Maine',
      providerName: 'Maine State Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official Maine Lottery',
          subtitle:
              'Winning numbers, draw games, and Maine Lottery information.',
          url: 'https://www.mainelottery.com/',
        ),
      ],
    ),
    'New Hampshire': StateLotterySource(
      stateName: 'New Hampshire',
      providerName: 'New Hampshire Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle:
              'Official New Hampshire Lottery results and game information.',
          url: 'https://www.nhlottery.com/',
        ),
        StateLotteryResource(
          title: 'Past winning numbers',
          subtitle: 'Search official New Hampshire Lottery drawing results.',
          url: 'https://nhlottery.com/winning/past-results',
        ),
      ],
    ),
    'Vermont': StateLotterySource(
      stateName: 'Vermont',
      providerName: 'Vermont Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Vermont Lottery results, jackpots, and games.',
          url: 'https://vtlottery.com/home-page',
        ),
        StateLotteryResource(
          title: 'Lottery information and FAQs',
          subtitle: 'Official Vermont Lottery rules, schedules, and guidance.',
          url: 'https://vtlottery.com/about/faq',
        ),
      ],
    ),
    'Massachusetts': StateLotterySource(
      stateName: 'Massachusetts',
      providerName: 'Massachusetts State Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Massachusetts Lottery winning numbers and games.',
          url: 'https://www.masslottery.com/',
        ),
        StateLotteryResource(
          title: 'Scratch and draw games',
          subtitle: 'Official Massachusetts game catalog and game details.',
          url: 'https://www.masslottery.com/games?game_types=Instant',
        ),
        StateLotteryResource(
          title: 'Recent winners',
          subtitle: 'Official Massachusetts Lottery winner results.',
          url: 'https://masslottery.com/winners',
        ),
      ],
    ),
    'Rhode Island': StateLotterySource(
      stateName: 'Rhode Island',
      providerName: 'Rhode Island Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Rhode Island Lottery results and current games.',
          url: 'https://www.rilot.com/',
        ),
        StateLotteryResource(
          title: 'Lottery FAQs',
          subtitle: 'Official information about results, prizes, and play.',
          url: 'https://www.rilot.com/en-us/player-zone/faqs.html',
        ),
      ],
    ),
    'Connecticut': StateLotterySource(
      stateName: 'Connecticut',
      providerName: 'Connecticut Lottery Corporation',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle:
              'Official Connecticut Lottery results and current jackpots.',
          url: 'https://www.ctlottery.org/',
        ),
        StateLotteryResource(
          title: 'Winning numbers archive',
          subtitle: 'Search official Connecticut Lottery results by game.',
          url: 'https://www.ctlottery.org/WinningNumbers/Lotto%21',
        ),
        StateLotteryResource(
          title: 'Scratch game prize table',
          subtitle:
              'Official Scratch-Off game details and unclaimed top prizes.',
          url: 'https://management.ctlottery.org/ScratchGamesTable',
        ),
      ],
    ),
    'Ohio': StateLotterySource(
      stateName: 'Ohio',
      providerName: 'Ohio Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official Ohio Lottery',
          subtitle:
              'Winning numbers, draw games, Scratch-Offs, and game details.',
          url: 'https://www.ohiolottery.com/',
        ),
        StateLotteryResource(
          title: 'Scratch-Off games and prizes',
          subtitle:
              'Official Ohio Scratch-Off games and remaining-prize details.',
          url: 'https://www.ohiolottery.com/games/scratch-offs/',
        ),
      ],
    ),
    'Michigan': StateLotterySource(
      stateName: 'Michigan',
      providerName: 'Michigan Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official Michigan Lottery',
          subtitle:
              'Official Michigan Lottery results, games, and player tools.',
          url: 'https://www.michiganlottery.com/',
        ),
        StateLotteryResource(
          title: 'Drawing results help',
          subtitle:
              'Official guidance for viewing prior Michigan draw results.',
          url:
              'https://help.michiganlottery.com/support/solutions/articles/158000441671-how-to-view-past-draws',
        ),
      ],
    ),
    'Indiana': StateLotterySource(
      stateName: 'Indiana',
      providerName: 'Hoosier Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official Hoosier Lottery',
          subtitle:
              'Official Indiana Lottery results, games, and player tools.',
          url: 'https://hoosierlottery.com/',
        ),
        StateLotteryResource(
          title: 'Check your numbers',
          subtitle: 'Search official Hoosier Lottery draw-game results.',
          url: 'https://hoosierlottery.com/games/draw/14/check-your-numbers/',
        ),
        StateLotteryResource(
          title: 'Scratch-Off games',
          subtitle: 'Official Hoosier Lottery Scratch-Off game catalog.',
          url: 'https://hoosierlottery.com/games/scratch-off/',
        ),
      ],
    ),
    'Illinois': StateLotterySource(
      stateName: 'Illinois',
      providerName: 'Illinois Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Illinois Lottery results, jackpots, and games.',
          url: 'https://www.illinoislottery.com/',
        ),
        StateLotteryResource(
          title: 'Instant tickets',
          subtitle: 'Official Illinois instant-ticket game catalog.',
          url: 'https://www.illinoislottery.com/games-hub/instant-tickets',
        ),
      ],
    ),
    'Wisconsin': StateLotterySource(
      stateName: 'Wisconsin',
      providerName: 'Wisconsin Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Wisconsin Lottery results, games, and jackpots.',
          url: 'https://www.wilottery.com/',
        ),
        StateLotteryResource(
          title: 'Past winning numbers',
          subtitle: 'Search official Wisconsin Lottery draw history.',
          url: 'https://www.wilottery.com/winners/draw-history',
        ),
      ],
    ),
    'Minnesota': StateLotterySource(
      stateName: 'Minnesota',
      providerName: 'Minnesota Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Minnesota Lottery results, games, and jackpots.',
          url: 'https://www.mnlottery.com/',
        ),
      ],
    ),
    'Iowa': StateLotterySource(
      stateName: 'Iowa',
      providerName: 'Iowa Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Iowa Lottery results and drawing information.',
          url:
              'https://ialottery.com/Pages/WinningNumbers/WinningNumbers_Main.aspx',
        ),
        StateLotteryResource(
          title: 'Iowa Lottery games',
          subtitle:
              'Official Iowa draw, Scratch, InstaPlay, and pull-tab games.',
          url: 'https://www.ialottery.com/Pages/Games/Games_main.aspx',
        ),
      ],
    ),
    'Missouri': StateLotterySource(
      stateName: 'Missouri',
      providerName: 'Missouri Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Missouri Lottery winning numbers and results.',
          url: 'https://molottery.com/winning-numbers/winning-numbers.jsp',
        ),
        StateLotteryResource(
          title: 'Scratchers',
          subtitle: 'Official Missouri Lottery Scratchers catalog and prizes.',
          url: 'https://www.molottery.com/scratchers-list.do?method=a',
        ),
      ],
    ),
    'Kansas': StateLotterySource(
      stateName: 'Kansas',
      providerName: 'Kansas Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official Kansas Lottery',
          subtitle: 'Official Kansas Lottery results, games, and information.',
          url: 'https://www.kslottery.gov/',
        ),
        StateLotteryResource(
          title: 'Scratch and pull-tab games',
          subtitle:
              'Official current Kansas scratch and pull-tab game catalog.',
          url: 'https://playonkansas.com/games/scratch-and-pull-tabs',
        ),
      ],
    ),
    'Nebraska': StateLotterySource(
      stateName: 'Nebraska',
      providerName: 'Nebraska Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official Nebraska Lottery',
          subtitle:
              'Official Nebraska Lottery results, games, and player tools.',
          url: 'https://nelottery.com/',
        ),
        StateLotteryResource(
          title: 'Top prizes remaining',
          subtitle: 'Official Nebraska Scratch-Off top-prize information.',
          url: 'https://demo.nelottery.com/homeapp/scratch/prizesremaining/pdf',
        ),
      ],
    ),
    'California': StateLotterySource(
      stateName: 'California',
      providerName: 'California State Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official California Lottery',
          subtitle:
              'Winning numbers, draw games, Scratchers, and player tools.',
          url: 'https://scorigin.calottery.com/en/',
        ),
        StateLotteryResource(
          title: 'California Scratchers',
          subtitle: 'Official Scratcher games, prizes, and top-prize status.',
          url: 'https://scorigin.calottery.com/en/scratchers',
        ),
      ],
    ),
    'Oregon': StateLotterySource(
      stateName: 'Oregon',
      providerName: 'Oregon Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official Oregon Lottery',
          subtitle: 'Official Oregon Lottery results, games, and player tools.',
          url: 'https://www.oregonlottery.org/',
        ),
      ],
    ),
    'Washington': StateLotterySource(
      stateName: 'Washington',
      providerName: "Washington's Lottery",
      resources: [
        StateLotteryResource(
          title: 'Official Washington Lottery',
          subtitle:
              'Official Washington Lottery results, games, and player tools.',
          url: 'https://www.walottery.com/Home/',
        ),
        StateLotteryResource(
          title: 'Winning numbers',
          subtitle: 'Official Washington Lottery draw-game results.',
          url: 'https://walottery.com/WinningNumbers/Default.aspx',
        ),
      ],
    ),
    'Idaho': StateLotterySource(
      stateName: 'Idaho',
      providerName: 'Idaho Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official Idaho Lottery',
          subtitle: 'Official Idaho Lottery results, games, and player tools.',
          url: 'https://www.idaholottery.com/',
        ),
        StateLotteryResource(
          title: 'Winning-number history',
          subtitle: 'Search official Idaho Lottery past winning numbers.',
          url: 'https://www.idaholottery.com/games/winning-numbers-history/',
        ),
        StateLotteryResource(
          title: 'Scratch games',
          subtitle: 'Official Idaho Lottery Scratch game catalog and prizes.',
          url: 'https://idaholottery.com/games',
        ),
      ],
    ),
    'Montana': StateLotterySource(
      stateName: 'Montana',
      providerName: 'Montana Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official Montana Lottery',
          subtitle:
              'Official Montana Lottery results, games, and player tools.',
          url: 'https://montanalottery.com/',
        ),
        StateLotteryResource(
          title: 'Scratch games',
          subtitle: 'Official Montana Scratch games, odds, and prize details.',
          url: 'https://montanalottery.com/scratch-games/',
        ),
      ],
    ),
    'Wyoming': StateLotterySource(
      stateName: 'Wyoming',
      providerName: 'WyoLotto',
      resources: [
        StateLotteryResource(
          title: 'Official WyoLotto',
          subtitle:
              'Official Wyoming Lottery results, games, and player tools.',
          url: 'https://wyolotto.com/',
        ),
        StateLotteryResource(
          title: 'Past winning numbers',
          subtitle: 'Search official WyoLotto draw-game results.',
          url: 'https://wyolotto.com/wyo-wins/check-your-numbers',
        ),
      ],
    ),
    'Colorado': StateLotterySource(
      stateName: 'Colorado',
      providerName: 'Colorado Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official Colorado Lottery',
          subtitle:
              'Official Colorado Lottery results, games, and player tools.',
          url: 'https://www.coloradolottery.com/en/',
        ),
        StateLotteryResource(
          title: 'Drawing history',
          subtitle: 'Search official Colorado Lottery winning-number history.',
          url:
              'https://www.coloradolottery.com/en/player-tools/winning-history/',
        ),
      ],
    ),
    'New Mexico': StateLotterySource(
      stateName: 'New Mexico',
      providerName: 'New Mexico Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official New Mexico Lottery',
          subtitle:
              'Official New Mexico Lottery results, games, and player tools.',
          url: 'https://www.nmlottery.com/',
        ),
        StateLotteryResource(
          title: 'Drawing results',
          subtitle: 'Official New Mexico Lottery draw-game results.',
          url: 'https://www.nmlottery.com/drawings/drawing-results/',
        ),
        StateLotteryResource(
          title: 'Scratchers',
          subtitle: 'Official New Mexico Scratcher games and prize details.',
          url: 'https://www.nmlottery.com/games/scratchers/',
        ),
      ],
    ),
    'Arizona': StateLotterySource(
      stateName: 'Arizona',
      providerName: 'Arizona Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Arizona Lottery results, games, and jackpots.',
          url: 'https://www.arizonalottery.com/',
        ),
        StateLotteryResource(
          title: 'Draw games',
          subtitle: 'Official Arizona draw-game information and schedules.',
          url: 'https://www.arizonalottery.com/draw-games/',
        ),
        StateLotteryResource(
          title: 'Scratchers',
          subtitle:
              'Official Arizona Scratcher games and top-prize information.',
          url: 'https://www.arizonalottery.com/scratchers/',
        ),
      ],
    ),
    'Texas': StateLotterySource(
      stateName: 'Texas',
      providerName: 'Texas Lottery Commission',
      resources: [
        StateLotteryResource(
          title: 'Official Texas Lottery',
          subtitle: 'Official Texas Lottery results, games, and player tools.',
          url: 'https://www.texaslottery.com/',
        ),
        StateLotteryResource(
          title: 'Check your numbers',
          subtitle: 'Search official Texas Lottery draw-game results.',
          url:
              'https://www.texaslottery.com/export/sites/lottery/Games/Check_Your_Numbers.html',
        ),
        StateLotteryResource(
          title: 'Current Scratch-Off games',
          subtitle: 'Official Texas Lottery current Scratch-Off game list.',
          url:
              'https://www.txbingo.org/export/sites/lottery/Games/Scratch_Offs/all.html_1537077106.html',
        ),
      ],
    ),
    'Arkansas': StateLotterySource(
      stateName: 'Arkansas',
      providerName: 'Arkansas Scholarship Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Arkansas Lottery results, games, and jackpots.',
          url: 'https://www.myarkansaslottery.com/',
        ),
        StateLotteryResource(
          title: 'Arkansas LOTTO results',
          subtitle: 'Official Arkansas LOTTO winning numbers and game details.',
          url: 'https://www.myarkansaslottery.com/games/lotto',
        ),
      ],
    ),
    'Louisiana': StateLotterySource(
      stateName: 'Louisiana',
      providerName: 'Louisiana Lottery Corporation',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Louisiana Lottery results, games, and jackpots.',
          url: 'https://louisianalottery.com/',
        ),
        StateLotteryResource(
          title: 'Louisiana Lotto results',
          subtitle:
              'Official Louisiana Lotto winning numbers and game details.',
          url: 'https://louisianalottery.com/draw-games/lotto/',
        ),
      ],
    ),
    'Mississippi': StateLotterySource(
      stateName: 'Mississippi',
      providerName: 'Mississippi Lottery Corporation',
      resources: [
        StateLotteryResource(
          title: 'Official Mississippi Lottery',
          subtitle:
              'Official Mississippi Lottery results, games, and player tools.',
          url: 'https://www.mslottery.com/',
        ),
      ],
    ),
    'Oklahoma': StateLotterySource(
      stateName: 'Oklahoma',
      providerName: 'Oklahoma Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle: 'Official Oklahoma Lottery results, games, and jackpots.',
          url: 'https://lottery.ok.gov/',
        ),
        StateLotteryResource(
          title: 'Scratchers',
          subtitle:
              'Official Oklahoma Scratcher games and top-prize information.',
          url: 'https://www.lottery.ok.gov/scratchers',
        ),
      ],
    ),
    'North Dakota': StateLotterySource(
      stateName: 'North Dakota',
      providerName: 'North Dakota Lottery',
      resources: [
        StateLotteryResource(
          title: 'Latest winning numbers',
          subtitle:
              'Official North Dakota Lottery results, jackpots, and game information.',
          url: 'https://lottery.nd.gov/public',
        ),
      ],
    ),
    'South Dakota': StateLotterySource(
      stateName: 'South Dakota',
      providerName: 'South Dakota Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official South Dakota Lottery',
          subtitle:
              'Official South Dakota Lottery results, games, and player tools.',
          url: 'https://lottery.sd.gov/',
        ),
        StateLotteryResource(
          title: 'Scratch games',
          subtitle: 'Official South Dakota Scratch games and prize details.',
          url: 'https://lottery.sd.gov/scratch-games/',
        ),
      ],
    ),
    'West Virginia': StateLotterySource(
      stateName: 'West Virginia',
      providerName: 'West Virginia Lottery',
      resources: [
        StateLotteryResource(
          title: 'Official West Virginia Lottery',
          subtitle:
              'Official West Virginia Lottery results, games, and player tools.',
          url: 'https://wvlottery.com/home',
        ),
        StateLotteryResource(
          title: 'Ticket checking guide',
          subtitle:
              'Official guidance for checking West Virginia Lottery tickets.',
          url:
              'https://wvlottery.com/content/beginners-guide-check-lottery-ticket-wv-lottery',
        ),
      ],
    ),
  };

  static StateLotterySource? forState(String stateName) => _sources[stateName];
}

class StateLotterySource {
  const StateLotterySource({
    required this.stateName,
    required this.providerName,
    required this.resources,
    this.hasVerifiedSchedule = false,
  });

  final String stateName;
  final String providerName;
  final List<StateLotteryResource> resources;
  final bool hasVerifiedSchedule;
}

class StateLotteryResource {
  const StateLotteryResource({
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final String title;
  final String subtitle;
  final String url;
}
