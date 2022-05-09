declare module '@idopterlabs/rn-zendesk' {

  // normal init function when you want to use all of the sdks
  export function init(initializationOptins: InitOptions): void;

  // function to display chat box
  export function startChat(chatOptions: ChatOptions): void;

  /** 
   *  function to show to support form
   * @example
   * ```ts
   * zendesk.startTicket();
   * ```
   */
  export function startTicket(): void;

  // function to list all tickets available 
  export function showTicketList(): void;

  // function to display chat if you have online agent or support form
  export function startChatOrTicket(chatOptions: ChatOptions): void;

  // function to request the generation of a new token in chat
  type CallbackRequestNewToken = () => void;

  // set user identity for authentication when you want to use chat or ticket sdk
  export function setUserIdentity(identity: Identity, onRequestNewToken: CallbackRequestNewToken): void;

  // set a new token for the chat
  export function updateUserToken(newToken: string): void;

  // function to set primary color code for the chat theme, pass hex code of the color here
  export function setPrimaryColor(color: string): void;

  // function to display help center UI
  export function showHelpCenter(chatOptions: ChatOptions): void;

  // function to set visitor info in chat
  export function setVisitorInfo(visitorInfo: UserInfo): void;

  // function to register notifications token with zendesk
  export function setNotificationToken(token: string): void;
  
  interface ChatOptions {
    botName?: string
    // boolean value if you want just chat sdk or want to use all the sdk like support, answer bot and chat
    // true value means just chat sdk
    chatOnly?: boolean
    // hex code color to set on chat
    color?: string
    /* help center specific props only */
    // sent in help center function only to show help center with/without chat
    withChat?: boolean
    // to enable/disable ticket creation in help center
    disableTicketCreation?: boolean
  }

  interface InitOptions {
    // chat key of zendesk account to init chat
    key: string,
    // appId of your zendesk account
    appId: string,
    // clientId of your zendesk account
    clientId: string,
    // support url of zendesk account
    url: string,
    // enable debug mode of zendesk sdk
    isEnabledLoggable?: boolean,
  }

  interface IdentityUser {
    // user name
    name: string,
    // user email
    email: string,
  }

  interface IdentityJwt {
    // jwt token
    token: string,
    // enabled jwt authentication in chat
    isEnabledJwtAuthenticator?: boolean,
  }

  interface UserInfo {
     // user's name
    name?: string
    // user's email
    email?: string
    // user's phone
    phone?: number
    // department to redirect the chat
    department?: string
    // tags for chat
    tags?: Array<string>
  }

  type Identity = IdentityJwt | IdentityUser;
}
