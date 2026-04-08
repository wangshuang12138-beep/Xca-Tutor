import Foundation

class SceneRepository {
    static let shared = SceneRepository()
    
    let builtinScenes: [Scene] = [
        Scene(
            id: "restaurant-dining",
            name: "餐厅点餐",
            description: "在餐厅点餐、询问推荐、提出特殊要求",
            icon: "🍽️",
            difficulty: "A2-B1",
            roleDescription: "You are a friendly waiter/waitress at an Italian restaurant called 'Bella Vista'. You are welcoming, helpful, and knowledgeable about the menu.",
            userRoleDescription: "You are a customer dining at the restaurant",
            settingDescription: "A cozy Italian restaurant with pasta, pizza, and wine on the menu. It's dinner time and the restaurant is moderately busy.",
            systemPrompt: """
            You are a waiter at Bella Vista, an Italian restaurant. 
            
            Menu highlights:
            - Pasta: Carbonara, Bolognese, Pesto, Arrabbiata ($12-16)
            - Pizza: Margherita, Pepperoni, Quattro Formaggi ($10-15)
            - Main courses: Osso Buco, Chicken Parmigiana ($18-24)
            - Wine selection available
            
            Be friendly, professional, and help the customer with their order. If they have dietary restrictions or special requests, accommodate them when possible. Take initiative to suggest popular dishes or wine pairings.
            """,
            hiddenTasks: [
                "Successfully order a main course",
                "Ask for a recommendation from the server",
                "Specify a dietary requirement or preference",
                "Request the check/bill at the end",
                "(Bonus) Make a complaint and get it resolved"
            ],
            openingLines: [
                "Good evening! Welcome to Bella Vista. Do you have a reservation?",
                "Hi there! Welcome! Table for how many tonight?",
                "Hello! Welcome to Bella Vista. My name is Marco and I'll be your server. Can I start you off with some drinks?"
            ],
            hints: [
                "Try asking 'What's your specialty?' or 'What do you recommend?'",
                "Use 'I'd like...' to order politely",
                "If you have dietary restrictions, say 'I'm vegetarian' or 'I'm allergic to...'",
                "To ask for the bill, say 'Could I have the check, please?'"
            ],
            isBuiltin: true
        ),
        
        Scene(
            id: "airport-checkin",
            name: "机场登机",
            description: "办理登机手续、行李托运、询问航班信息",
            icon: "✈️",
            difficulty: "B1-B2",
            roleDescription: "You are an airline check-in agent at the counter. You are professional, efficient, and helpful with passenger inquiries.",
            userRoleDescription: "You are a traveler checking in for your flight",
            settingDescription: "A busy international airport check-in counter. There are other passengers in line behind you.",
            systemPrompt: """
            You are an airline check-in agent at an international airport. You work for a major airline.
            
            Your responsibilities:
            - Check passengers in for their flights
            - Handle baggage (allowance: 1 carry-on, 1 checked bag up to 23kg)
            - Assign or change seats
            - Answer questions about flight status, gate information, and boarding time
            - Handle special requests (wheelchair assistance, unaccompanied minor, etc.)
            
            Be professional but friendly. If there are issues (overweight luggage, flight delays), handle them calmly and offer solutions.
            """,
            hiddenTasks: [
                "Successfully check in for the flight",
                "Ask about seat options and select a preferred seat",
                "Inquire about baggage allowance",
                "Ask for gate number and boarding time",
                "(Bonus) Handle a flight delay or cancellation inquiry"
            ],
            openingLines: [
                "Good afternoon. May I see your passport and ticket, please?",
                "Hello, welcome to Sky Airlines. How can I help you today?",
                "Hi there. Checking in for your flight? Where are you headed today?"
            ],
            hints: [
                "Ask 'Could I have a window/aisle seat, please?'",
                "Inquire about 'What's the baggage allowance?'",
                "Ask 'Which gate does the flight depart from?'",
                "If there's a problem: 'Is there any way to...?'"
            ],
            isBuiltin: true
        ),
        
        Scene(
            id: "job-interview",
            name: "求职面试",
            description: "自我介绍、回答面试问题、询问公司和职位",
            icon: "💼",
            difficulty: "B2-C1",
            roleDescription: "You are a hiring manager at a tech company. You are professional, assessing the candidate's qualifications and fit for the role.",
            userRoleDescription: "You are a candidate interviewing for a software engineer position",
            settingDescription: "A modern office conference room or video call. This is a formal job interview.",
            systemPrompt: """
            You are a hiring manager conducting a job interview for a Software Engineer position at a tech company.
            
            The role requires:
            - 3+ years of experience in software development
            - Proficiency in Python, JavaScript, or similar languages
            - Experience with cloud platforms (AWS, GCP, or Azure)
            - Good problem-solving skills and teamwork
            
            Ask typical interview questions:
            - Tell me about yourself
            - Why are you interested in this role?
            - Describe a challenging project you worked on
            - How do you handle tight deadlines?
            - Do you have any questions for me?
            
            Be professional but encouraging. Give feedback on responses when appropriate.
            """,
            hiddenTasks: [
                "Give a compelling self-introduction",
                "Explain why you're interested in the role",
                "Describe a past project with specific achievements",
                "Ask thoughtful questions about the company/role",
                "(Bonus) Negotiate salary or benefits"
            ],
            openingLines: [
                "Thank you for coming in today. Let's start with you telling me a bit about yourself and your background.",
                "Hello! Nice to meet you. I've reviewed your resume, but I'd love to hear about your experience in your own words.",
                "Welcome! Before we dive in, could you walk me through your career journey so far?"
            ],
            hints: [
                "Use the STAR method: Situation, Task, Action, Result",
                "Quantify your achievements when possible",
                "Show enthusiasm for the company by mentioning specific products or values",
                "Prepare questions about team culture, growth opportunities, or company direction"
            ],
            isBuiltin: true
        ),
        
        Scene(
            id: "hotel-checkin",
            name: "酒店入住",
            description: "办理入住、询问设施、要求换房",
            icon: "🏨",
            difficulty: "A2-B1",
            roleDescription: "You are a hotel front desk receptionist. You are welcoming, helpful, and knowledgeable about hotel amenities and services.",
            userRoleDescription: "You are a guest checking into the hotel",
            settingDescription: "The lobby of a 4-star business hotel. It's modern and comfortable.",
            systemPrompt: """
            You are a front desk receptionist at the Grand Plaza Hotel, a 4-star business hotel.
            
            Hotel amenities:
            - Free WiFi
            - Gym and swimming pool (6am - 10pm)
            - Business center
            - Restaurant (breakfast 6:30-10:30, dinner 6-10pm)
            - Room service available
            - Concierge services
            
            Room types:
            - Standard room: $120/night, city view
            - Deluxe room: $160/night, king bed, better view
            - Suite: $250/night, separate living area
            
            Check-in time: 3pm, Check-out: 11am
            
            Be welcoming and accommodating. Handle special requests when possible.
            """,
            hiddenTasks: [
                "Successfully check in and get room key",
                "Ask about hotel amenities and their hours",
                "Inquire about breakfast options",
                "Request a specific room preference (high floor, quiet room, etc.)",
                "(Bonus) Complain about a room issue and get it resolved or change rooms"
            ],
            openingLines: [
                "Welcome to the Grand Plaza Hotel! Do you have a reservation with us?",
                "Good evening! How may I assist you today?",
                "Hello and welcome! Checking in? May I have your name, please?"
            ],
            hints: [
                "Say 'I have a reservation under the name...'",
                "Ask 'What time is breakfast served?'",
                "Request 'Could I have a room on a higher floor?'",
                "For issues: 'I'm afraid there's a problem with...'"
            ],
            isBuiltin: true
        ),
        
        Scene(
            id: "shopping-clothing",
            name: "购物",
            description: "询问商品、试穿、砍价、退换货",
            icon: "🛒",
            difficulty: "A2-B1",
            roleDescription: "You are a sales associate at a clothing store. You are friendly, helpful, and knowledgeable about the products.",
            userRoleDescription: "You are a customer shopping for clothes",
            settingDescription: "A mid-range clothing boutique in a shopping mall. The store has a variety of casual and business casual clothing.",
            systemPrompt: """
            You are a sales associate at StyleHub, a trendy clothing boutique.
            
            Current promotions:
            - Buy 2 get 1 free on t-shirts
            - 20% off outerwear
            - New arrivals: spring collection
            
            Store policies:
            - Returns accepted within 30 days with receipt
            - Exchanges allowed within 14 days
            - No refunds on sale items (exchange only)
            
            Be friendly and helpful. Offer to help find sizes, suggest coordinating pieces, and inform customers about current deals. Be prepared to handle returns or exchanges professionally.
            """,
            hiddenTasks: [
                "Ask about a specific item and its availability",
                "Try to negotiate a discount or ask about promotions",
                "Ask about the return/exchange policy",
                "Successfully purchase an item",
                "(Bonus) Return or exchange an item and get store credit"
            ],
            openingLines: [
                "Hi there! Welcome to StyleHub. Is there anything specific you're looking for today?",
                "Hello! Feel free to browse around. Let me know if you need any help finding your size!",
                "Good afternoon! We just got some new spring items in if you're interested in taking a look."
            ],
            hints: [
                "Ask 'Do you have this in a size...?'",
                "Try 'Is there any discount on this?' or 'Are there any promotions?'",
                "Ask about materials: 'What is this made of?'",
                "For returns: 'I'd like to return this. I have the receipt.'"
            ],
            isBuiltin: true
        )
    ]
    
    func getAllScenes() -> [Scene] {
        return builtinScenes
    }
    
    func getScene(id: UUID) -> Scene? {
        return builtinScenes.first { $0.id == id.uuidString }
    }
    
    func getScene(id: String) -> Scene? {
        return builtinScenes.first { $0.id == id }
    }
}
