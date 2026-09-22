# Raid Waiting Arcade

Addon for World of Warcraft. Listed in the addon list as **[MANACODE] Arcade** (Russian client: **[MANACODE] Аркада**). Author: Manacode. Version 0.9.0, beta.

Twenty mini-games inside the game client for the time between joining a raid and the first pull. Each game takes a few minutes. A game saves on Esc and survives `/reload`. Four games can be played with another person: Chess, Checkers, Pairs and Chests. Both players need the addon and must be on the same realm and faction; distance does not matter.

## Games

- Apothecary — sort herbs into vials so each colour ends up alone in its own.
- Arkanoid — levels run one after another as long as you have balls.
- Bubbles — clear connected groups of stones; the bigger the group, the more points.
- Checkers (2 players) — Russian checkers, captures are mandatory, against the bot or a friend.
- Chess (2 players) — standard chess against another person; there is no bot.
- Chests (2 players) — a memory card game against the character at the table or against a friend.
- Construction — a crane swings a floor on a cable; a precise landing fills the floor with tenants.
- Invaders — waves of enemies from above; auto-fire, spacebar for the ability.
- Jumper — the character jumps on its own, arrow keys steer it sideways; climb as high as you can.
- Match Three — swap adjacent gems and match lines of three or more.
- Merge — slide the board with arrow keys; two matching potions merge into the next recipe.
- Mines — clear the minefield; the number on a tile tells how many mines are nearby.
- Pairs (2 players) — flip two cards at a time and find the matches.
- Recipe — guess the secret recipe in a few pinches: brew the mix and read the result.
- Slide — a picture cut up and shuffled; tiles slide into the empty spot.
- Snake — eat food without hitting a wall or biting your own tail.
- Solitaire — Klondike, FreeCell and Yukon.
- Storekeeper — push crates under the crane, fill in pits and clear a full row.
- Sudoku — digits 1–9 with no repeats in any row, column or box.
- Tetris — a 10-by-20 board: pieces fall, full lines clear.

Languages: English and Russian.

## Supported clients

| Client | Status |
|---|---|
| WoW 3.3.5a (Wrath of the Lich King private servers) | Main target |
| Retail WoW, Midnight 12.1 | Tested by the author |
| WoW: Forever (beta) | Experimental, not tested |

Known issue of the Forever beta client itself: it does not load addon saved data on login, so records and settings reset. This will stay until Forever's release.

## Installation

1. Download the zip from the Releases page: https://github.com/dmitriinosach/-MANACODE-RaidWaitingArcade/releases
2. Extract it into the game's `Interface\AddOns` folder. Inside the zip is the folder `ManaCode_RaidWaitingArcade`. It must keep exactly this name.
   - 3.3.5a: `<client folder>\Interface\AddOns`
   - Retail: `World of Warcraft\_retail_\Interface\AddOns`
3. Do not use GitHub's green "Code → Download ZIP" button. That archive has a different folder name and the game will not load the addon.
4. Fully restart the game client. A `/reload` is not enough for a newly installed addon.

## Usage

- `/arc` — open or close the window. `/arcade` and the minimap button do the same.
- `/arc chess` — open a game directly, past the menu. Game ids: `apothecary arkanoid breaker checkers chess gems gofish invaders jump merge mines pairs recipe slide snake solitaire stack sudoku tetris tower`.
- `/arc about` — window with links: releases, Discord. The client cannot open links, so the address is shown pre-selected for Ctrl+C.
- `/arc broken` — which games were disabled by an error, and why.

Entering combat pauses the game; with the "Hide window in combat" option the window also leaves the screen. A ready check or a group invite pauses the game, but the window stays up. The window does not take over the keyboard: Enter opens chat, Esc closes the arcade. Games use the arrow keys and spacebar only while a game is running; keys can be reassigned, and most games play with the mouse alone.

## Bug reports

The addon prints errors. The command `/arc broken` shows details. Report in Discord: channel `#arcade-bugs` (English) or `#arcade-баги` (Russian). Include the error text, your client (3.3.5, Midnight, Forever) and a screenshot.

## Links

- Website: https://wow-addons.manacode.su/en/arcade/ (English), https://wow-addons.manacode.su/arcade/ (Russian)
- Discord: https://discord.gg/CYnxS6R9qY
- Releases: https://github.com/dmitriinosach/-MANACODE-RaidWaitingArcade/releases

Download only from the Releases page, the website or the Discord server. Do not run addon files sent by other people.

---

# Raid Waiting Arcade

Аддон для World of Warcraft. В списке аддонов называется **[MANACODE] Аркада** (в английском клиенте — **[MANACODE] Arcade**). Автор: Manacode. Версия 0.9.0, бета.

Двадцать мини-игр внутри клиента на время между сбором рейда и первым пулом. Каждая партия занимает несколько минут. Партия сохраняется по Esc и переживает `/reload`. Четыре игры можно играть с другим человеком: Шахматы, Шашки, Пары и Сундучки. Аддон нужен обоим, и оба должны быть на одном сервере и одной фракции; расстояние не важно.

## Игры

- Аптекарь — разлить травы по колбам так, чтобы каждый цвет остался только в одной.
- Арканоид — уровни идут один за другим, пока есть мячи.
- Шарики — убирать связные группы камней; чем больше группа, тем больше очков.
- Шашки (вдвоём) — русские шашки, бой обязателен, с ботом или с напарником.
- Шахматы (вдвоём) — обычные шахматы с живым человеком; бота нет.
- Сундучки (вдвоём) — карточная игра на память против персонажа за столом или против друга.
- Стройка — кран качает этаж на тросе; точная посадка селит полный этаж жильцов.
- Захватчики — волны врагов сверху; огонь сам, пробел — способность.
- Джампер — персонаж прыгает сам, стрелки ведут его вбок; забраться повыше.
- Три в ряд — менять местами соседние камни и собирать линии от трёх одинаковых.
- Слияние — сдвигать поле стрелками; два одинаковых зелья дают следующий рецепт.
- Сапёр — разминировать поле; число на клетке говорит, сколько мин рядом.
- Пары (вдвоём) — открывать карточки по две и находить одинаковые.
- Рецепт — подобрать тайный рецепт из нескольких щепотей: варить смесь и читать ответ.
- Пятнашки — картинка разрезана и перемешана; плитки сдвигаются в пустую клетку.
- Змейка — съесть еду, не врезаться в стену и не откусить себе хвост.
- Пасьянс — Косынка, Свободная ячейка и Юкон.
- Кладовщик — толкать ящики под краном, заваливать ямы и собирать целый ряд.
- Судоку — цифры 1–9 без повторов в строке, в столбце и в квадрате.
- Тетрис — поле 10 на 20: фигуры падают, заполненные линии исчезают.

Языки: русский и английский.

## Поддерживаемые клиенты

| Клиент | Состояние |
|---|---|
| WoW 3.3.5a (приватные серверы Wrath of the Lich King) | Основная цель |
| Ретейл WoW, Midnight 12.1 | Проверено автором |
| WoW: Forever (бета) | Экспериментально, не проверено |

Известная проблема самого бета-клиента Forever: он не загружает сохранённые данные аддонов при входе, поэтому рекорды и настройки сбрасываются. Так будет до релиза Forever.

## Установка

1. Скачать zip со страницы релизов: https://github.com/dmitriinosach/-MANACODE-RaidWaitingArcade/releases
2. Распаковать в папку игры `Interface\AddOns`. Внутри архива папка `ManaCode_RaidWaitingArcade`. Имя менять нельзя.
   - 3.3.5a: `<папка клиента>\Interface\AddOns`
   - Ретейл: `World of Warcraft\_retail_\Interface\AddOns`
3. Не пользоваться зелёной кнопкой GitHub «Code → Download ZIP». У того архива другое имя папки, и игра аддон не загрузит.
4. Полностью перезапустить клиент игры. Для только что установленного аддона `/reload` недостаточно.

## Использование

- `/arc` — открыть или закрыть окно. То же делают `/arcade` и значок у миникарты.
- `/arc chess` — сразу в игру, мимо меню. Идентификаторы игр: `apothecary arkanoid breaker checkers chess gems gofish invaders jump merge mines pairs recipe slide snake solitaire stack sudoku tetris tower`.
- `/arc about` — окно со ссылками: релизы, Discord. Открыть ссылку клиент не умеет, поэтому адрес встаёт выделенным под Ctrl+C.
- `/arc broken` — какие игры отключились из-за ошибки и почему.

Вход в бой ставит партию на паузу; с галочкой «Прятать окно в бою» окно ещё и уходит с экрана. Проверка готовности и приглашение в группу ставят партию на паузу, но окно остаётся. Окно не забирает клавиатуру: Enter открывает чат, Esc закрывает аркаду. Играм отдаются стрелки и пробел, и только на время партии; клавиши переназначаются, большинство игр играется одной мышью.

## Сообщить об ошибке

Аддон печатает ошибки. Команда `/arc broken` показывает подробности. Писать в Discord: канал `#arcade-баги` (русский) или `#arcade-bugs` (английский). Приложить текст ошибки, свой клиент (3.3.5, Midnight, Forever) и скриншот.

## Ссылки

- Сайт: https://wow-addons.manacode.su/arcade/ (русский), https://wow-addons.manacode.su/en/arcade/ (английский)
- Discord: https://discord.gg/CYnxS6R9qY
- Релизы: https://github.com/dmitriinosach/-MANACODE-RaidWaitingArcade/releases

Скачивать только со страницы релизов, с сайта или с сервера Discord. Не запускать файлы аддона, присланные другими людьми.
