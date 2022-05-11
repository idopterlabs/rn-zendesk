declare module '@idopterlabs/rn-zendesk' {
  /**
   * Initialize the SDK
   * @param initializationOptions Startup and Access Settings
   * 
   * @example
   * ```ts
   * RNZendesk.init({
   *  key: 'ip1MZws0A17aDjg8wjfs2sfQ8AeUJFe5',
   *  appId: 'd89309417eb165b6b5041234371c16a5bsjfc2f49a027b4c',
   *  clientId: 'mobile_sdk_client_9326b42367cca4c2d2f',
   *  url: 'https://MY_ZENDESK.zendesk.com',
   *  isEnabledLoggable: false,
   * });
   * ```
   */
  export function init(initializationOptions: InitOptions): void;

  /**
   * Open the chat
   * @param chatOptions Chat settings
   * 
   * @example
   * ```ts
   * RNZendesk.startChat({});
   * ```
   */
  export function startChat(chatOptions: ChatOptions): void;

  /** 
   * Open the ticket form
   * @example
   * ```ts
   * RNZendesk.startTicket();
   * ```
   */
  export function startTicket(): void;

  /** 
   * Open the page with all user tickets
   * @example
   * ```ts
   * RNZendesk.showTicketList();
   * ```
   */
  export function showTicketList(): void;

  /** 
   * Display chat if you have online agent or ticket form
   * @param chatOptions Chat settings
   * 
   * @example
   * ```ts
   * RNZendesk.startChatOrTicket({});
   * ```
   */
  export function startChatOrTicket(chatOptions: ChatOptions): void;

  // Callback interface to request the generation of a new token in chat
  export type CallbackRequestNewToken = () => void;

  /** 
   * Set user identity for authentication when you want to use chat or ticket sdk
   * @param chatOptions Chat settings
   * 
   * @example
   * ```ts
   * RNZendesk.setUserIdentity({
   *  token: '1234567890abcdef',
   *  isEnabledJwtAuthenticator: true
   * }, async () => {
   *  RNZendesk.updateUserToken('1234567890abcdef');
   * });
   * ```
   */
  export function setUserIdentity(identity: Identity, onRequestNewToken: CallbackRequestNewToken): void;

  /** 
   * Set a new token for the chat
   * @param newToken Token string
   * 
   * @example
   * ```ts
   * RNZendesk.updateUserToken('1234567890abcdef');
   * ```
   */
  export function updateUserToken(newToken: string): void;

  /** 
   * Set primary color code for the chat theme
   * @param color HEX Color String
   * 
   * @example
   * ```ts
   * RNZendesk.setPrimaryColor('#3762ff');
   * ```
   */
  export function setPrimaryColor(color: string): void;

  /** 
   * Open the help center
   * @param chatOptions Chat settings
   * 
   * @example
   * ```ts
   * RNZendesk.showHelpCenter({});
   * ```
   */
  export function showHelpCenter(chatOptions: ChatOptions): void;

  /** 
   * Set visitor info in chat
   * @param visitorInfo User info
   * 
   * @example
   * ```ts
   * RNZendesk.setVisitorInfo({});
   * ```
   */
  export function setVisitorInfo(visitorInfo: UserInfo): void;

  /** 
   * Register notifications token with zendesk
   * @param token Token string
   * 
   * @example
   * ```ts
   * RNZendesk.setNotificationToken('123456');
   * ```
   */
  export function setNotificationToken(token: string): void;
  
  export interface ChatOptions {
    // Name bot
    botName?: string
    // Show only chat without support, answer bot
    chatOnly?: boolean 
    // Sent in help center function only to show help center with chat
    withChat?: boolean
    // Disable ticket creation in help center
    disableTicketCreation?: boolean
  }

  export interface InitOptions {
    // Chat key of zendesk account to init chat
    key: string,
    // AppId of your zendesk account
    appId: string,
    // ClientId of your zendesk account
    clientId: string,
    // Support url of zendesk account
    url: string,
    // Enable debug mode of zendesk sdk
    isEnabledLoggable?: boolean,
  }

  export interface IdentityUser {
    // User name
    name: string,
    // User email
    email: string,
  }

  export interface IdentityJwt {
    // JWT token
    token: string,
    // Enabled jwt authentication in chat
    isEnabledJwtAuthenticator?: boolean,
  }

  export interface UserInfo {
     // User's name
    name?: string
    // User's email
    email?: string
    // User's phone
    phone?: number
    // Department to redirect the chat
    department?: string
    // Tags for chat
    tags?: Array<string>
  }

  export type Identity = IdentityJwt | IdentityUser;
}
