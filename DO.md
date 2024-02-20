## Dynamic Custom Topic Quiz Challenge: Project Description

Step into the future of trivia with the Dynamic Custom Topic Quiz Challenge, a revolutionary quiz platform where you're in control. Select from an endless array of topics and tailor your gameplay with difficulty settings. Immerse in the thrill of real-time, multiplayer action and compete for high scores. Seamlessly balanced with advanced security and rapid-fire performance - no lag, no downtime, just pure knowledge and fun. This is where instant gratification meets the intellect. Get ready to challenge your brain, climb the leaderboards, and be part of a vibrant trivia community. Are you up for the challenge?

### Essential Features

#### Topic Selection
- **Multiple Topic Choice:** Enables players to handpick their preferred quiz topics from a diverse selection.
- [x] Available when creating a new game room
- **Selective Difficulty Levels:** Allows players to adjust the challenge level of their quizzes.
- [x] Available when creating a new game room
- **Randomized Topic Mix Option:** Offers a randomized topic selection for a more varied quiz experience.
- [x] Available when creating a new game room (button supprise me)

#### OpenAI API Integration
- **Real-time Question Generation:** Utilizes the OpenAI API to craft unique, on-the-spot questions each quiz round.
- [x] Questions are generated in real-time using OpenAI's GPT-3 API
- **Contextual Hints and Explanations:** Provides players with hints during the quiz and explanations after answering, leveraging OpenAI's information processing capabilities.
- [x] Questions are generated with hints and explanations, hint appears after 2/3 of the time has passed, and explanation appears after the question is answered

#### Live Multiplayer Sessions
- **Private/Public Game Rooms:** Players can join public game rooms or create private ones for an exclusive group experience.
- [x] Players can create private game rooms with a password
- **Instant Player Joining:** Ensures a fluid game joining process for players who wish to participate in ongoing quiz games.
- [x] Players can join a game room by entering the room code and if game is already started they will join the game in progress

#### Scoring System
- **Points Based on Response Accuracy:** Points are awarded for each correct answer, encouraging the accuracy of responses.
- [x] Players are awarded points for each correct answer, more over they are awarded bonus points for winstreaks
- **Bonus Points for Speed:** Time-based point bonuses add a competitive element to the game, rewarding quick-witted players.
- [x] Players are awarded points for answering quickly, the faster they answer the more points they get

#### Game Rounds
- **Configurable Number of Questions:** Players have control over the number of questions per quiz, allowing for quick or extended play.
- [x] Available when creating a new game room
- **Option to Set Round Limits:** Provides the flexibility to set a fixed number of rounds, catering to different game session lengths.
- [x] Available when creating a new game room

### Technical Bonuses

#### Security Enhancements
- **JWT Authentication:** Introduces a secure token-based system to manage user sessions and access control.
- [x] Users are authenticated using JWT tokens, but unlogged users can access the game annonymously

#### Performance Features
- **Caching:** Implements strategic data caching to decrease latency, enhance the user experience, and minimize API requests to OpenAI.
- [ ] Caching is not implemented in the current version

#### Scalability Additions
- **Horizontal Scaling with Redis:** Adopts Redis for session and state management in a distributed server environment, facilitating smooth performance even during high load and ensuring the system can scale out efficiently.
- [x] Horizontal Scaling is implemented with dnscluster. It allow to scale the system by adding more nodes to the cluster and the communication between nodes is handled by the library, that's ensure the system can scale out efficiently

---

By integrating these essential features with the additional technical bonuses, the Dynamic Custom Topic Quiz Challenge is designed to provide an immersive educational gaming experience while maintaining high performance, security, and the ability to scale, catering to a broad user base.
