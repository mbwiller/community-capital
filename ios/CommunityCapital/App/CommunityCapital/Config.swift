struct Config {
    static let apiURL = "http://localhost:3000/api"
    static let websocketURL = "ws://localhost:3000"
    
    struct Stripe {
        static let publishableKey = "pk_test_51RsYTRFqqgZ0ydP8oymhadMQN2Gnsf8R9s03UcVRonAP7iDobzlvEYsuAu17RcX1BeH1nMk1LEQCgdrRyp9mO0Ox00staWEM3U"
    }
    
    struct Plaid {
        static let publicKey = "689260cbee10d400241033c5"
    }
}
