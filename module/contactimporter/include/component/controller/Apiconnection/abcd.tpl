<?php


if(!extension_loaded('oauth')) {
  
  require_once('OAuth.php');
} else {
 
  throw new LinkedInException('LinkedIn: library not compatible with installed PECL OAuth extension.  Please disable this extension to use the Simple-LinkedIn library.');
}

/**
 * 'LinkedInException' class declaration.
 *  
 * This class extends the base 'Exception' class.
 * 
 * @access  public
 * @package classpackage
 */
class LinkedInException extends Exception {}

/**
 * 'linked' class declaration.
 *  
 * This class provides generalized LinkedIn oauth functionality.
 * 
 * @access  public
 * @package classpackage
 */
class linkedin_API {
  // api keys (live and development, if applicable)
  const _API_KEY                     = 'AVcg-WVWOehWLJHyRHiGVmlS6qomhiPrSAMYMf9YX527uLYRXtIaNLWNanepUKD1';
  const _API_SECRET                  = 'xwmR1-hQhoG1TpGSiJVYnqPqSi8xT0z9V12EUxWk0L3gmsE3aR1D7HM_Y536RXSG';
  const _API_DEV_MODE                = FALSE;
  const _API_DEV_KEY                 = '<your development application key here>';
  const _API_DEV_SECRET              = '<your development application secret here>';
  
  // the default response format from LinkedIn
  const _DEFAULT_RESPONSE_FORMAT     = 'xml';
    
  // helper constants used to standardize LinkedIn <-> API communication.  See demo page for usage.
  const _GET_RESPONSE                = 'lResponse';
  const _GET_TYPE                    = 'lType';
  
  // Invitation API constants.
  const _INV_SUBJECT                 = 'Invitation to connect';
  const _INV_BODY_LENGTH             = 200;
  
  // Network API constants.
  const _NETWORK_LENGTH              = 1000;
  const _NETWORK_HTML                = '<a>';
  
  // response format type constants
  const _RESPONSE_JSON               = 'JSON';
  const _RESPONSE_JSONP              = 'JSONP';
  const _RESPONSE_XML                = 'XML';
  
  // Share API constants
  const _SHARE_COMMENT_LENGTH        = 700;
  const _SHARE_CONTENT_TITLE_LENGTH  = 200;
  const _SHARE_CONTENT_DESC_LENGTH   = 400;
  
  // LinkedIn API end-points
    const _URL_ACCESS                  = 'https://api.linkedin.com/uas/oauth/accessToken';
    const _URL_API                     = 'https://api.linkedin.com';
    const _URL_AUTH                    = 'https://www.linkedin.com/uas/oauth/authorize?oauth_token=';
    const _URL_REQUEST                 = 'https://api.linkedin.com/uas/oauth/requestToken';
    const _URL_REVOKE                  = 'https://api.linkedin.com/uas/oauth/invalidateToken';
    
    // Library version
    const _VERSION                     = '2.1.0';

  public $consumer, $method;
  
  // the format of the data to return
  public $response_format            = self::_DEFAULT_RESPONSE_FORMAT;
  
  protected $callback;
  protected $token_access, $token_request;
  
    /**
     * Create a LinkedIn object, used for OAuth-based authentication and 
     * communication with the LinkedIn API.     
     * 
     * @param    str   $callback_url   [OPTIONAL] The URL to return the user to.
     * @return   obj                   A new LinkedIn object.     
     */
    public function __construct($callback_url = NULL) {
      if(self::_API_DEV_MODE) {
        // 'development' mode
          $this->consumer = new OAuthConsumer(self::_API_DEV_KEY, self::_API_DEV_SECRET, $callback_url);
    } else {
      // 'live' mode
      $this->consumer = new OAuthConsumer(self::_API_KEY, self::_API_SECRET, $callback_url);
    }        
        $this->method = new OAuthSignatureMethod_HMAC_SHA1();
        $this->set_callback($callback_url);
    }
    
    /**
   * The class destructor.
   * 
   * Explicitly clears LinkedIn object from memory upon destruction.
     */
  public function __destruct() {
    unset($this);
    }
    
    /**
     * Post a comment on an existing connections shared content.  API details can
     * be found here: 
     * 
     * http://developer.linkedin.com/docs/DOC-1043 
     * 
     * @param    str   $uid            The LinkedIn update ID.        
     * @param    str   $comment        The share comment to be posted.     
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.            
     */
    public function comment($uid, $comment) {
      // check passed data
      if(!is_string($uid)) {
        // bad data passed
          throw new LinkedInException('LinkedIn->comment(): bad data passed, $uid must be of type string.');
      }
    if(!is_string($comment)) {
      // nothing/non-string passed, raise an exception
          throw new LinkedInException('LinkedIn->comment(): bad data passed, $comment must be a non-zero length string.');
    }
    
    /**
     * Share comment rules:
     * 
     * 1) No HTML permitted.
     * 2) Comment cannot be longer than 700 characters.     
     */
    $comment = substr(trim(htmlspecialchars(strip_tags($comment))), 0, self::_SHARE_COMMENT_LENGTH);
        $data    = '<?xml version="1.0" encoding="UTF-8"?>
                <update-comment>
                          <comment>' . $comment . '</comment>
                        </update-comment>';

    // send request
    $comment_url  = self::_URL_API . '/v1/people/~/network/updates/key=' . $uid . '/update-comments';
    $response     = $this->request('POST', $comment_url, $data);
    
    /**
       * Check for successful comment (a 201 response from LinkedIn server) 
       * per the documentation linked in method comments above.
       */ 
    if($response['info']['http_code'] == 201) {
      // comment successful
      $return_data            = $response;
      $return_data['success'] = TRUE;
    } else {
      // problem posting our comment
      $return_data            = $response;
      $return_data['success'] = FALSE;
    }
        return $return_data;
    }
    
    /**
     * Return all comments associated with a given network update:
     * 
     * http://developer.linkedin.com/docs/DOC-1043
     * 
     * @param    str   $uid            The LinkedIn update ID.              
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.                  
     */
    public function comments($uid) {
      // check passed data
      if(!is_string($uid)) {
        // bad data passed
          throw new LinkedInException('LinkedIn->comments(): bad data passed, $uid must be of type string.');
      }
        
        // send request
    $comments_url = self::_URL_API . '/v1/people/~/network/updates/key=' . $uid . '/update-comments';
    $response     = $this->request('GET', $comments_url);
    
      /**
       * Check for successful comments retrieval (a 200 response from LinkedIn server) 
       * per the documentation linked in method comments above.
       */ 
    if($response['info']['http_code'] == 200) {
      // comments retrieval successful
      $return_data            = $response;
      $return_data['success'] = TRUE;
    } else {
      // problem getting the comments
      $return_data            = $response;
      $return_data['success'] = FALSE;
    }
    return $return_data;
    }
    
    /**
     * General connection retrieval function.
     * 
     * Takes a string of parameters as input and requests connection-related data 
     * from the Linkedin Connections API.  See the official documentation for 
     * $options 'field selector' formatting:
     * 
     * http://developer.linkedin.com/docs/DOC-1014           
     * 
     * @param    str   $options        [OPTIONAL] Data retrieval options.     
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.
     */
    public function connections($options = '~/connections') {
      // check passed data
      if(!is_string($options)) {
        // bad data passed
          throw new LinkedInException('LinkedIn->connections(): bad data passed, $options must be of type string.');
      }
      
      $query    = self::_URL_API . '/v1/people/' . trim($options);
      $response = $this->request('GET', $query);
      if($response['info']['http_code'] == 200) {
        // connections request successful
        $return_data            = $response;
        $return_data['success'] = TRUE;
      } else {
        // connections request failed
        $return_data            = $response;
        $return_data['success'] = FALSE;
      }
        return $return_data;
    }
    
    /**
     * Get the callback property.
     * 
     * @return   str                   The callback url.            
     */
    public function get_callback() {
      return $this->callback;
    }
  
  /**
     * Get the response_format property.
     * 
     * @return   str                   The response format.            
     */
    public function get_response_format() {
      return $this->response_format;
    }
    
    /**
     * Get the token_access property.
     * 
     * @return   arr                   The access token.            
     */
    public function get_token_access() {
      return $this->token_access;
    }
    
    /**
     * Get the token_request property.
     * 
     * @return   arr                   The request token.            
     */
    public function get_token_request() {
      return $this->token_request;
    }
    
    /**
     * Send an invitation to connect to your network, either by email address or 
     * by LinkedIn ID.  Details on the API here: 
     * 
     * http://developer.linkedin.com/docs/DOC-1012
     * 
     * @param    str   $method         The invitation method to process.     
     * @param    var   $recipient      The email/id to send the invitation to.          
     * @param    str   $subject        The subject of the invitation to send.
     * @param    str   $body           The body of the invitation to send.
     * @param    str   $type           [OPTIONAL] The invitation request type (only friend is supported at this time by the Invite API).
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.       
     */
    public function invite($method, $recipient, $subject, $body, $type = 'friend') {
    /**
     * Clean up the passed data per these rules:
     * 
     * 1) Message must be sent to one recipient (only a single recipient permitted for the Invitation API)
     * 2) No HTML permitted
     * 3) 200 characters max in the invitation subject
     * 4) Only able to connect as a friend at this point     
     */
    // check passed data
    switch($method) {
      case 'email':
        if(is_array($recipient)) {
          $recipient = array_map('trim', $recipient);
        } else {
          // bad format for recipient for email method
          throw new LinkedInException('LinkedIn->invite(): invitation recipient email/name array is malformed.');
        }
        break;
      case 'id':
        $recipient = trim($recipient);
        if(!self::is_id($recipient)) {
          // bad format for recipient for id method
          throw new LinkedInException('LinkedIn->invite(): invitation recipient ID does not match LinkedIn format.');
        }
        break;
      default:
        throw new LinkedInException('LinkedIn->invite(): bad invitation method, must be one of: email, id.');
        break;
    }
    if(!empty($recipient)) {
      if(is_array($recipient)) {
        $recipient = array_map('trim', $recipient);
      } else {
        // string value, we assume
        $recipient = trim($recipient);
      }
    } else {
      // no recipient
      throw new LinkedInException('LinkedIn->invite(): you must provide a single invitation recipient.');
    }
    if(!empty($subject)) {
      $subject = trim(strip_tags(stripslashes($subject)));
    } else {
      throw new LinkedInException('LinkedIn->invite(): message subject is empty.');
    }
    if(!empty($body)) {
      $body = trim(strip_tags(stripslashes($body)));
    } else {
      throw new LinkedInException('LinkedIn->invite(): message body is empty.');
    }
    switch($type) {
      case 'friend':
        break;
      default:
        throw new LinkedInException('LinkedIn->invite(): bad invitation type, must be one of: friend.');
        break;
    }
    
    // construct the xml data
        $data   = '<?xml version="1.0" encoding="UTF-8"?>
                   <mailbox-item>
                     <recipients>
                   <recipient>';
                     switch($method) {
                       case 'email':
                         // email-based invitation
                         $data .= '<person path="/people/email=' . $recipient['email'] . '">
                                     <first-name>' . $recipient['first-name'] . '</first-name>
                                     <last-name>' . $recipient['last-name'] . '</last-name>
                                   </person>';
                         break;
                       case 'id':
                         // id-based invitation
                         $data .= '<person path="/people/id=' . $recipient . '"/>';
                         break;
                     }
    $data  .= '    </recipient>
                 </recipients>
                 <subject>' . $subject . '</subject>
                 <body>' . $body . '</body>
                 <item-content>
                   <invitation-request>
                     <connect-type>';
                       switch($type) {
                         case 'friend':
                           $data .= 'friend';
                           break;
                       }
    $data  .= '      </connect-type>';
                     switch($method) {
                       case 'id':
                         // id-based invitation, we need to get the authorization information
                         $query                 = 'id=' . $recipient . ':(api-standard-profile-request)';
                         $response              = self::profile($query);
                         if($response['info']['http_code'] == 200) {
                           $response['linkedin'] = self::xml_to_array($response['linkedin']);
                           if($response['linkedin'] === FALSE) {
                             // bad XML data
                             throw new LinkedInException('LinkedIn->update_network(): LinkedIn returned bad XML data.');
                           }
                           $authentication = explode(':', $response['linkedin']['person']['children']['api-standard-profile-request']['children']['headers']['children']['http-header']['children']['value']['content']);
                           
                           // complete the xml        
                           $data .= '<authorization>
                                       <name>' . $authentication[0] . '</name>
                                       <value>' . $authentication[1] . '</value>
                                     </authorization>';
                         } else {
                           // bad response from the profile request, not a valid ID?
                           throw new LinkedInException('LinkedIn->invite(): could not send invitation, LinkedIn says: ' . print_r($response['linkedin'], TRUE));
                         }
                         break;
                     }
    $data  .= '    </invitation-request>
                 </item-content>
               </mailbox-item>';
    
    // send request
    $invite_url = self::_URL_API . '/v1/people/~/mailbox';
    $response   = $this->request('POST', $invite_url, $data);
        
        /**
       * Check for successful update (a 201 response from LinkedIn server) 
       * per the documentation linked in method comments above.
       */ 
    if($response['info']['http_code'] == 201) {
      // status update successful
      $return_data            = $response;
      $return_data['success'] = TRUE;
    } else {
      // problem posting our connection message(s)
      $return_data            = $response;
      $return_data['success'] = FALSE;
    }
        return $return_data;
    }
    
    /**
     * Checks the passed string $id to see if it has a valid LinkedIn ID format, 
     * which is, as of October 15th, 2010:
     * 
     * 10 alpha-numeric mixed-case characters, plus underscores and dashes.               
     * 
     * @param    str   $id             A possible LinkedIn ID.              
     * @return   bool                  TRUE/FALSE depending on valid ID format determination.                  
     */
    public static function is_id($id) {
      // check passed data
    if(!is_string($id)) {
        // bad data passed
        throw new LinkedInException('LinkedIn->is_id(): bad data passed, $id must be of type string.');
      }
      
      $pattern = '/^[a-z0-9_\-]{10}$/i';
      if($match = preg_match($pattern, $id)) {
        // we have a match
        $return_data = TRUE;
      } else {
        // no match
        $return_data = FALSE;
      }
      return $return_data;
    }
    
    /**
     * Checks the passed LinkedIn response to see if we have hit a throttling 
     * limit:
     * 
     * http://developer.linkedin.com/docs/DOC-1112
     * 
     * @param    arr   $response       The LinkedIn response.              
     * @return   bool                  TRUE/FALSE depending on content of response.                  
     */
    public static function is_throttled($response) {
      $return_data = FALSE;
    
    // check the variable
      if(!empty($response) && is_string($response)) {
        // we have an array and have a properly formatted linkedin response
           
      // store the response in a temp variable
      $temp_response = self::xml_to_array($response);
        if($temp_response !== FALSE) {
          // check to see if we have an error
          if(array_key_exists('error', $temp_response) && ($temp_response['error']['children']['status']['content'] == 403) && preg_match('/throttle/i', $temp_response['error']['children']['message']['content'])) {
            // we have an error, it is 403 and we have hit a throttle limit
            $return_data = TRUE;
          }
        }
      }
      return $return_data;
    }
    
    /**
     * Like another user's network update:
     * 
     * http://developer.linkedin.com/docs/DOC-1043
     * 
     * @param    str   $uid            The LinkedIn update ID.              
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.                  
     */
    public function like($uid) {
      // check passed data
      if(!is_string($uid)) {
        // bad data passed
          throw new LinkedInException('LinkedIn->like(): bad data passed, $uid must be of type string.');
      }
    
    // construct the xml data
        $data = '<?xml version="1.0" encoding="UTF-8"?>
                 <is-liked>true</is-liked>';
        
        // send request
    $like_url = self::_URL_API . '/v1/people/~/network/updates/key=' . $uid . '/is-liked';
    $response = $this->request('PUT', $like_url, $data);
    
      /**
       * Check for successful like (a 201 response from LinkedIn server) 
       * per the documentation linked in method comments above.
       */ 
    if($response['info']['http_code'] == 201) {
      // like update successful
      $return_data            = $response;
      $return_data['success'] = TRUE;
    } else {
      // problem posting our like
      $return_data            = $response;
      $return_data['success'] = FALSE;
    }
    return $return_data;
    }
    
    /**
     * Return all likes associated with a given network update:
     * 
     * http://developer.linkedin.com/docs/DOC-1043
     * 
     * @param    str   $uid            The LinkedIn update ID.              
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.                  
     */
    public function likes($uid) {
      // check passed data
      if(!is_string($uid)) {
        // bad data passed
          throw new LinkedInException('LinkedIn->likes(): bad data passed, $uid must be of type string.');
      }
        
        // send request
    $likes_url  = self::_URL_API . '/v1/people/~/network/updates/key=' . $uid . '/likes';
    $response   = $this->request('GET', $likes_url);
    
      /**
       * Check for successful likes retrieval (a 200 response from LinkedIn server) 
       * per the documentation linked in method comments above.
       */ 
    if($response['info']['http_code'] == 200) {
      // likes retrieval successful
      $return_data            = $response;
      $return_data['success'] = TRUE;
    } else {
      // problem getting the likes
      $return_data            = $response;
      $return_data['success'] = FALSE;
    }
    return $return_data;
    }
    
    /**
     * Send a message to your network connection(s), optionally copying yourself.  
     * Full details from LinkedIn on this functionality can be found here: 
     * 
     * http://developer.linkedin.com/docs/DOC-1044
     * 
     * @param    arr   $recipients     The connection(s) to send the message to.          
     * @param    str   $subject        The subject of the message to send.
     * @param    str   $body           The body of the message to send.     
     * @param    bool  $copy_self      [OPTIONAL] Also update the teathered Twitter account.     
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.           
     */
    public function message($recipients, $subject, $body, $copy_self = FALSE) {
    /**
     * Clean up the passed data per these rules:
     * 
     * 1) Message must be sent to at least one recipient
     * 2) No HTML permitted
     */
    if(!empty($subject)) {
      $subject = trim(strip_tags(stripslashes($subject)));
    } else {
      throw new LinkedInException('LinkedIn->message(): message subject is empty.');
    }
    if(!empty($body)) {
      $body = trim(strip_tags(stripslashes($body)));
    } else {
      throw new LinkedInException('LinkedIn->message(): message body is empty.');
    }
    if(!is_array($recipients) || count($recipients) < 1) {
      // no recipients, and/or bad data
      throw new LinkedInException('LinkedIn->message(): at least one message recipient required.');
    }
    
    // construct the xml data
        $data   = '<?xml version="1.0" encoding="UTF-8"?>
                   <mailbox-item>
                     <recipients>';
    $data  .=     ($copy_self) ? '<recipient><person path="/people/~"/></recipient>' : '';
                  for($i = 0; $i < count($recipients); $i++) {
                    $data .= '<recipient><person path="/people/' . trim($recipients[$i]) . '"/></recipient>';
                  }
    $data  .= '  </recipients>
                 <subject>' . $subject . '</subject>
                 <body>' . $body . '</body>
               </mailbox-item>';
    
    // send request
    $message_url  = self::_URL_API . '/v1/people/~/mailbox';
    $response     = $this->request('POST', $message_url, $data);
        
        /**
       * Check for successful update (a 201 response from LinkedIn server) 
       * per the documentation linked in method comments above.
       */ 
    if($response['info']['http_code'] == 201) {
      // message(s) sent successfully
      $return_data            = $response;
      $return_data['success'] = TRUE;
    } else {
      // problem sending message(s)
      $return_data            = $response;
      $return_data['success'] = FALSE;
    }
        return $return_data;
    }
    
    /**
     * General profile retrieval function.
     * 
     * Takes a string of parameters as input and requests profile data from the 
     * Linkedin Profile API.  See the official documentation for $options
     * 'field selector' formatting:
     * 
     * http://developer.linkedin.com/docs/DOC-1014
     * http://developer.linkedin.com/docs/DOC-1002    
     * 
     * @param    str   $options        [OPTIONAL] Data retrieval options.     
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.
     */
    public function profile($options = '~') {
      // check passed data
      if(!is_string($options)) {
        // bad data passed
          throw new LinkedInException('LinkedIn->profile(): bad data passed, $options must be of type string.');
      }
      
      $query = self::_URL_API . '/v1/people/' . trim($options);
      $response = $this->request('GET', $query);
      if($response['info']['http_code'] == 200) {
        // profile request successful
        $return_data            = $response;
        $return_data['success'] = TRUE;
      } else {
        // profile request failed
        $return_data            = $response;
        $return_data['success'] = FALSE;
      }
        return $return_data;
    }
    
    /**
     * General data send/request method.
     * 
     * @param    str   $method         The data communication method.     
     * @param    str   $url            The Linkedin API endpoint to connect with.
     * @param    str   $data           [OPTIONAL] The data to send via to LinkedIn.     
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.
     */
    protected function request($method, $url, $data = NULL) {
      try {
          $oauth_req = OAuthRequest::from_consumer_and_token($this->consumer, $this->get_token_access(), $method, $url);
      $oauth_req->sign_request($this->method, $this->consumer, $this->get_token_access());
      switch($method) {
        case 'DELETE':
        case 'GET':
          return $this->send_request($oauth_req, $url, $method);
          break;
        case 'POST':
        case 'PUT':
          return $this->send_request($oauth_req, $url, $method, $data);
          break;
      }
    } catch(OAuthException $e) {
      // oauth exception raised
      throw new LinkedInException('OAuth exception caught: ' . $e->getMessage());
    }
    }
    
    /**
     * Revoke the current user's access token, clear the access token's from 
     * current linkedin object.  The current documentation for this feature is 
     * found in a blog entry from April 29th, 2010:
     * 
     * http://developer.linkedin.com/community/apis/blog/2010/04/29/oauth--now-for-authentication     
     * 
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.        
     */
    public function revoke() {
      try {
        // create oauth components of request
        $oauth_req = OAuthRequest::from_consumer_and_token($this->consumer, $this->get_token_access(), 'GET', self::_URL_REVOKE);
      $oauth_req->sign_request($this->method, $this->consumer, $this->get_token_access());
        
        // send request
        $response = $this->send_request($oauth_req, linkedin_API::_URL_REVOKE, 'GET');
        
        /**
         * Check for successful revocation (a 200 response from LinkedIn server) 
         * per the documentation linked in method comments above.
         */                      
        if($response['info']['http_code'] == 200) {
        // revocation successful, clear object's request/access tokens
        $this->set_token_access(NULL);
        $this->set_token_request(NULL);
        $return_data            = $response;
        $return_data['success'] = TRUE;
      } else {
        $return_data            = $response;
        $return_data['success'] = FALSE;
      }
      return $return_data;
    } catch(OAuthException $e) {
      // oauth exception raised
      throw new LinkedInException('OAuth exception caught: ' . $e->getMessage());
    }
    }
    
    /**
     * General people search function.
     * 
     * Takes a string of parameters as input and requests profile data from the 
     * Linkedin People Search API.  See the official documentation for $options
     * querystring formatting:
     * 
     * http://developer.linkedin.com/docs/DOC-1191 
     * 
     * @param    str   $options        [OPTIONAL] Data retrieval options.     
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.
     */
    public function search($options = NULL) {
      // check passed data
    if(!is_null($options) && !is_string($options)) {
        // bad data passed
          throw new LinkedInException('LinkedIn->search(): bad data passed, $options must be of type string.');
      }
      
    $query    = self::_URL_API . '/v1/people-search' . trim($options);
        $response = $this->request('GET', $query);
        if($response['info']['http_code'] == 200) {
        // search request successful
        $return_data            = $response;
        $return_data['success'] = TRUE;
      } else {
        // search request failed
        $return_data            = $response;
        $return_data['success'] = FALSE;
      }
        return $return_data;
    }
    
    /**
     * Linkedin cURL specific method, returning response:
     * 
     * array(
     *   'info'      =>    Connection information,
     *   'linkedin'  => LinkedIn response,  
     *   'oauth'     => The OAuth request string that was sent to LinkedIn     
     * )        
     * 
     * @param    obj   $request        The oauth request object to use.
     * @param    str   $url            Url to send data to.
     * @param    str   $method         Http protocol method.
     * @param    str   $data           [OPTIONAL] Data to send with the request.              
     * @return   arr                   A array containing the LinkedIn response and the connection information.                  
     */
    protected function send_request($request, $url, $method, $data = NULL) {
      // check for cURL
      if(!extension_loaded('curl')) {
        // cURL not present
      throw new LinkedInException('LinkedIn->send_request(): PHP cURL extension does not appear to be loaded/present.');
      }
      
    // start cURL, checking for a successful initiation
    if($handle = curl_init()) {
      // set cURL options, based on parameters passed
        curl_setopt($handle, CURLOPT_HEADER, 0);
      curl_setopt($handle, CURLOPT_RETURNTRANSFER, 1);
      curl_setopt($handle, CURLOPT_SSL_VERIFYPEER, 0);
      curl_setopt($handle, CURLOPT_URL, $url);
      
      // check the method we are using to communicate with LinkedIn
      switch($method) {
        case 'DELETE':
          curl_setopt($handle, CURLOPT_CUSTOMREQUEST, $method);
          break;
        case 'POST':
        case 'PUT':
          curl_setopt($handle, CURLOPT_POST, 1);
          curl_setopt($handle, CURLOPT_CUSTOMREQUEST, $method);
          break;
      }
      
      // configure the ehader we are sending to LinkedIn
      $header = array($request->to_header());
      if(is_null($data)) {
        switch($this->get_response_format()) {
          case self::_RESPONSE_JSON:
            $header[] = 'x-li-format: json';
            break;
          case self::_RESPONSE_JSONP:
            $header[] = 'x-li-format: jsonp';
            break;
        }
      } else {
        $header[] = 'Content-Type: text/xml; charset=UTF-8';
        curl_setopt($handle, CURLOPT_POSTFIELDS, $data);
      }
      curl_setopt($handle, CURLOPT_HTTPHEADER, $header);
      
      // gather the response
      $return_data['oauth']     = $request->base_string;
      $return_data['linkedin']  = curl_exec($handle);
      $return_data['info']      = curl_getinfo($handle);
      
      // check for throttling
      if(self::is_throttled($return_data['linkedin'])) {
        throw new LinkedInException('LinkedIn->send_request(): throttling limit has been reached.');
      }
      
      // close cURL connection
      curl_close($handle);
      
      // no exceptions thrown, return the data
      return $return_data;
    } else {
      // cURL failed to start
      throw new LinkedInException('LinkedIn->send_request(): cURL did not initialize properly.');
    }
    }
    
    /**
     * Set the callback property.
     * 
     * @param   str    $url            The callback url.            
     */
    public function set_callback($url) {
      $this->callback = $url;
    }
    
    /**
     * Set the response_format property.
     * 
     * @param   str    $format         [OPTIONAL] The response format to specify to LinkedIn.            
     */
    public function set_response_format($format = self::_DEFAULT_RESPONSE_FORMAT) {
      $this->response_format = $format;
    }
    
    /**
     * Set the token_access property.
     * 
     * @return   arr   $token_access   [OPTIONAL] The LinkedIn OAuth access token. 
     * @return   bool                  TRUE on success, FALSE if oauth generates an exception.           
     */
    public function set_token_access($token_access = NULL) {
    // check passed data
    if(!is_null($token_access) && !is_array($token_access)) {
      // bad data passed
      throw new LinkedInException('LinkedIn->set_token_access(): bad data passed, $token_access should be in array format.');
    }
    
    $return_data = TRUE;
    if(is_null($token_access)) {
        // null value passed, set the token to null
        $this->token_access = NULL;
      } else {
        // something passed, set token
        try {
          $this->token_access = new OAuthToken($token_access['oauth_token'], $token_access['oauth_token_secret']);
        } catch(OAuthException $e) {
        // error creating token
        $this->token_access   = NULL;
        $return_data          = FALSE;
        throw new LinkedInException('OAuth exception caught: ' . $e->getMessage());
      }
      }
      return $return_data;
    }
    
    /**
     * Set the token_request property.
     * 
     * @return   arr   $token_request  [OPTIONAL] The LinkedIn OAuth request token. 
     * @return   bool                  TRUE on success, FALSE if OAuth generates an exception.      
     */
    public function set_token_request($token_request = NULL) {
      // check passed data
      if(!is_null($token_request) && !is_array($token_request)) {
      // bad data passed
      throw new LinkedInException('LinkedIn->set_token_request(): bad data passed, $token_request should be in array format.');
    }
        
    $return_data = TRUE;
    if(is_null($token_request)) {
        // null value passed, set the token to null
        $this->token_request = NULL;
      } else {
        // something passed, set token
        try {
        $this->token_request = new OAuthToken($token_request['oauth_token'], $token_request['oauth_token_secret']);
      } catch(OAuthException $e) {
        // error creating token
        $this->token_request  = NULL;
        $return_data          = FALSE;
        throw new LinkedInException('OAuth exception caught: ' . $e->getMessage());
      }
      }
      return $return_data;
    }
    
    /**
     * Create a new or reshare another user's shared content.  Full details from 
     * LinkedIn on this functionality can be found here: 
     * 
     * http://developer.linkedin.com/docs/DOC-1212 
     * 
     * $action values: ('new', 'reshare')           
     * $content format: 
     *   $action = 'new'; $content => ('comment' => 'xxx', 'title' => 'xxx', 'submitted-url' => 'xxx', 'submitted-image-url' => 'xxx', 'description' => 'xxx')
     *   $action = 'reshare'; $content => ('comment' => 'xxx', 'id' => 'xxx')     
     * 
     * @param    str   $action         The sharing action to perform.     
     * @param    str   $content        The share content.
     * @param    bool  $private        [OPTIONAL] Should we restrict this shared item to connections only?     
     * @param    bool  $twitter        [OPTIONAL] Also update the teathered Twitter account.     
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.           
     */
    public function share($action, $content, $private = TRUE, $twitter = FALSE) {
      // check the status itself
    if(!empty($action) && !empty($content)) {
      /**
       * Status is not empty, wrap a cleaned version of it in xml.  Status
       * rules:
       * 
       * 1) Comments are 700 chars max (if this changes, change _SHARE_COMMENT_LENGTH constant)
       * 2) Content/title 200 chars max (if this changes, change _SHARE_CONTENT_TITLE_LENGTH constant)
       * 3) Content/description 400 chars max (if this changes, change _SHARE_CONTENT_DESC_LENGTH constant)
       * 4a) New shares must contain a comment and/or (content/title and content/submitted-url)
       * 4b) Reshared content must contain an attribution id.
       * 4c) Reshared content must contain actual content, not just a comment.             
       * 5) No HTML permitted in comment, content/title, content/description.
       */

      // prepare the share data per the rules above
      $share_flag   = FALSE;
      $content_xml  = NULL;
      if(array_key_exists('comment', $content)) {
        // comment located
        $comment = substr(trim(strip_tags(stripslashes($content['comment']))), 0, self::_SHARE_COMMENT_LENGTH);
        $content_xml .= '<comment>' . $comment . '</comment>';
        $share_flag = TRUE;
      }
      switch($action) {
        case 'new':
          if(array_key_exists('title', $content) && array_key_exists('submitted-url', $content)) {
            // we have shared content, format it as needed per rules above
            $content_title = substr(trim(strip_tags(stripslashes($content['title']))), 0, self::_SHARE_CONTENT_TITLE_LENGTH);
            $content_xml .= '<content>
                               <title>' . $content_title . '</title>
                               <submitted-url>' . trim($content['submitted-url']) . '</submitted-url>';
            if(array_key_exists('submitted-image-url', $content)) {
              $content_xml .= '<submitted-image-url>' . trim($content['submitted-image-url']) . '</submitted-image-url>';
            }
            if(array_key_exists('description', $content)) {
              $content_desc = substr(trim(strip_tags(stripslashes($content['description']))), 0, self::_SHARE_CONTENT_DESC_LENGTH);
              $content_xml .= '<description>' . $content_desc . '</description>';
            }
            $content_xml .= '</content>';
            $share_flag = TRUE;
          }
          break;
        case 'reshare':
          if(array_key_exists('id', $content)) {
            // put together the re-share attribution XML
            $content_xml .= '<attribution>
                               <share>
                                 <id>' . trim($content['id']) . '</id>
                               </share>
                             </attribution>';
          } else {
            // missing required piece of data
            $share_flag = FALSE;
          }
          break;
        default:
          // bad action passed
          throw new LinkedInException('LinkedIn->share(): share action is an invalid value, must be one of: share, reshare.');
          break;
      }
      
      // should we proceed?
      if($share_flag) {
        // put all of the xml together
        $visibility = ($private) ? 'connections-only' : 'anyone';
        $data       = '<?xml version="1.0" encoding="UTF-8"?>
                       <share>
                         ' . $content_xml . '
                         <visibility>
                           <code>' . $visibility . '</code>
                         </visibility>
                       </share>';
        
        // create the proper url
        $share_url = self::_URL_API . '/v1/people/~/shares';
            if($twitter) {
                // update twitter as well
          $share_url .= '?twitter-post=true';
              }
        
        // send request
        $response = $this->request('POST', $share_url, $data);
          } else {
            // data contraints/rules not met, raise an exception
            throw new LinkedInException('LinkedIn->share(): sharing data constraints not met; check that you have supplied valid content and combinations of content to share.');
          }
    } else {
      // data missing, raise an exception
          throw new LinkedInException('LinkedIn->share(): sharing action or shared content is missing.');
    }
    
    /**
       * Check for successful update (a 201 response from LinkedIn server) 
       * per the documentation linked in method comments above.
       */ 
    if($response['info']['http_code'] == 201) {
      // status update successful
      $return_data            = $response;
      $return_data['success'] = TRUE;
    } else {
      // problem putting our status update
      $return_data            = $response;
      $return_data['success'] = FALSE;
    }
        return $return_data;
    }
    
    /**
     * General network statistics retrieval function.
     * 
     * Returns the number of connections, second-connections an authenticated
     * user has.  More information here:
     * 
     * http://developer.linkedin.com/docs/DOC-1006
     * 
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.
     */
    public function statistics() {
      $query    = self::_URL_API . '/v1/people/~/network/network-stats';
        $response = $this->request('GET', $query);
        if($response['info']['http_code'] == 200) {
        // statistics request successful
        $return_data            = $response;
        $return_data['success'] = TRUE;
      } else {
        // statistics request failed
        $return_data            = $response;
        $return_data['success'] = FALSE;
      }
        return $return_data;
    }
    
    /**
     * Request the user's access token from the Linkedin API.
     * 
     * @param    str   $token          The token returned from the user authorization stage.
     * @param    str   $secret         The secret returned from the request token stage.
     * @param    str   $verifier       The verification value from LinkedIn.     
     * @return   arr                   The Linkedin OAuth/http response, in array format.           
     */
    public function token_access($token, $secret, $verifier) {
      // check passed data
    if(!is_string($token) || !is_string($secret) || !is_string($verifier)) {
      // nothing passed, raise an exception
          throw new LinkedInException('LinkedIn->token_access(): bad data passed, string type is required for $token, $secret and $verifier.');
    }
    
    // start retrieval process
      try {
        $token_access = new OAuthToken($token, $secret);
        $oauth_req = OAuthRequest::from_consumer_and_token($this->consumer, $token_access, 'POST', linkedin_API::_URL_ACCESS);
      $oauth_req->set_parameter('oauth_verifier', $verifier);
      $oauth_req->sign_request($this->method, $this->consumer, $token_access);
      
      $response = $this->send_request($oauth_req, linkedin_API::_URL_ACCESS, 'POST');
      parse_str($response['linkedin'], $response['linkedin']);
      //sadkjasjdga
      if($response['info']['http_code'] == 200) {
        // tokens retrieved
        $this->set_token_access($response['linkedin']);
        
        // set the response
        $return_data            = $response;
        $return_data['success'] = TRUE;
      } else {
        // error getting the request tokens
        $this->set_token_access(NULL);
        
        // set the response
        $return_data            = $response;
        $return_data['success'] = FALSE;
      }
      return $return_data;
    } catch(OAuthException $e) {
      // oauth exception raised
      throw new LinkedInException('OAuth exception caught: ' . $e->getMessage());
    }
    }
    
    /**
     * Get the request token from the Linkedin API.
     * 
     * @return   arr                   The Linkedin OAuth/http response, in array format.           
     */
    public function token_request() {
      try {
        $oauth_req = OAuthRequest::from_consumer_and_token($this->consumer, NULL, 'POST', linkedin_API::_URL_REQUEST);
      $oauth_req->set_parameter('oauth_callback', $this->get_callback());
      $oauth_req->sign_request($this->method, $this->consumer, NULL);
      
      $response = $this->send_request($oauth_req, linkedin_API::_URL_REQUEST, 'POST');
      parse_str($response['linkedin'], $response['linkedin']);
        //sss]\sss
      if ( isset($response['linkedin']['oauth_problem']) && $response['linkedin']['oauth_problem'] == 'timestamp_refused')
      {
          $tmp = (int)$response['linkedin']['oauth_acceptable_timestamps'];
          $_SESSION['delta_time_stamp'] = $tmp-time();
          $this->token_request() ;
          
      }
      if($response['info']['http_code'] == 200) {
        // tokens retrieved
        $this->set_token_request($response['linkedin']);
        
        // set the response
        $return_data            = $response;
        $return_data['success'] = TRUE;        
      } else {
        // error getting the request tokens
        $this->set_token_request(NULL);
        
        // set the response
        $return_data            = $response;
        $return_data['success'] = FALSE;
      }
      return $return_data;
    } catch(OAuthException $e) {
      // oauth exception raised
      
      throw new LinkedInException('OAuth exception caught: ' . $e->getMessage());
    }
    }
    
    /**
     * Unlike another user's network update:
     * 
     * http://developer.linkedin.com/docs/DOC-1043
     * 
     * @param    str   $uid            The LinkedIn update ID.              
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.                  
     */
    public function unlike($uid) {
      // check passed data
      if(!is_string($uid)) {
        // bad data passed
          throw new LinkedInException('LinkedIn->unlike(): bad data passed, $uid must be of type string.');
      }
    
    // construct the xml data
        $data = '<?xml version="1.0" encoding="UTF-8"?>
                 <is-liked>false</is-liked>';
        
        // send request
    $like_url = self::_URL_API . '/v1/people/~/network/updates/key=' . $uid . '/is-liked';
    $response = $this->request('PUT', $like_url, $data);
    
      /**
       * Check for successful unlike (a 201 response from LinkedIn server) 
       * per the documentation linked in method comments above.
       */ 
    if($response['info']['http_code'] == 201) {
      // unlike update successful
      $return_data            = $response;
      $return_data['success'] = TRUE;
    } else {
      // problem unliking
      $return_data            = $response;
      $return_data['success'] = FALSE;
    }
    return $return_data;
    }
    
    /**
     * Update the user's Linkedin network status.  Full details from LinkedIn 
     * on this functionality can be found here: 
     * 
     * http://developer.linkedin.com/docs/DOC-1009
     * http://developer.linkedin.com/docs/DOC-1009#comment-1077 
     * 
     * @param    str   $update         The network update.     
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.            
     */
    public function update_network($update) {
      // check passed data
    if(!is_string($update)) {
      // nothing/non-string passed, raise an exception
          throw new LinkedInException('LinkedIn->update_network(): bad data passed, $update must be a non-zero length string.');
    }
    
    /**
     * Network update is not empty, wrap a cleaned version of it in xml.  
     * Network update rules:
     * 
     * 1) No HTML permitted except those found in _NETWORK_HTML constant
     * 2) Update cannot be longer than 140 characters.     
     */
    // get the user data
    $response = self::profile('~:(first-name,last-name,site-standard-profile-request)');
    if($response['success'] === TRUE) {
      /** 
       * We are converting response to usable data.  I'd use SimpleXML here, but
       * to keep the class self-contained, we will use a portable XML parsing
       * routine, self::xml_to_array.       
       */
      $person = self::xml_to_array($response['linkedin']);
      if($person === FALSE) {
        // bad xml data
        throw new LinkedInException('LinkedIn->update_network(): LinkedIn returned bad XML data.');
      }
          $fields = $person['person']['children'];
  
          // prepare user data
          $first_name   = trim($fields['first-name']['content']);
          $last_name    = trim($fields['last-name']['content']);
          $profile_url  = trim($fields['site-standard-profile-request']['children']['url']['content']);
  
      // create the network update 
      $update = substr(trim(htmlspecialchars(strip_tags($update, self::_NETWORK_HTML))), 0, self::_NETWORK_LENGTH);
      $user   = htmlspecialchars('<a href="' . $profile_url . '">' . $first_name . ' ' . $last_name . '</a>');
          $data   = '<activity locale="en_US">
                           <content-type>linkedin-html</content-type>
                           <body>' . $user . ' ' . $update . '</body>
                         </activity>';
  
      // send request
      $update_url = self::_URL_API . '/v1/people/~/person-activities';
      $response   = $this->request('POST', $update_url, $data);
      
      /**
         * Check for successful update (a 201 response from LinkedIn server) 
         * per the documentation linked in method comments above.
         */ 
      if($response['info']['http_code'] == 201) {
        // network update successful
        $return_data            = $response;
        $return_data['success'] = TRUE;
      } else {
        // problem posting our network update
        $return_data            = $response;
        $return_data['success'] = FALSE;
      }
    } else {
      // profile retrieval failed
      throw new LinkedInException('LinkedIn->update_network(): profile data could not be retrieved.');
    }
        return $return_data;
    }
    
  /**
     * General network update retrieval function.
     * 
     * Takes a string of parameters as input and requests update-related data 
     * from the Linkedin Network Updates API.  See the official documentation for 
     * $options parameter formatting:
     * 
     * http://developer.linkedin.com/docs/DOC-1006
     * 
     * For getting more comments, likes, etc, see here:
     * 
     * http://developer.linkedin.com/docs/DOC-1043              
     * 
     * @param    str   $options        [OPTIONAL] Data retrieval options.     
     * @return   arr                   Array containing retrieval success, LinkedIn XML formatted response.
     */
    public function updates($options = NULL) {
      // check passed data
    if(!is_null($options) && !is_string($options)) {
        // bad data passed
          throw new LinkedInException('LinkedIn->updates(): bad data passed, $options must be of type string.');
      }
      
    $query    = self::_URL_API . '/v1/people/~/network/updates' . trim($options);
      $response = $this->request('GET', $query);
      if($response['info']['http_code'] == 200) {
        // profile request successful
        $return_data            = $response;
        $return_data['success'] = TRUE;
      } else {
        // profile request failed
        $return_data            = $response;
        $return_data['success'] = FALSE;
      }
        return $return_data;
    }
    
    /**
     * Converts passed XML data to an array.
     * 
     * @param    str   $xml            The XML to convert to an array.     
     * @return   arr                   Array containing the XML data.     
     * @return   bool                  FALSE if passed data cannot be parsed to an array.          
     */
    public static function xml_to_array($xml) {
      // check passed data
    if(!is_string($xml)) {
        // bad data possed
      throw new LinkedInException('LinkedIn->xml_to_array(): bad data passed, $xml must be a non-zero length string.');
      }
      
      $parser = xml_parser_create();
      xml_parser_set_option($parser, XML_OPTION_CASE_FOLDING, 0);
    xml_parser_set_option($parser, XML_OPTION_SKIP_WHITE, 1);
    if(xml_parse_into_struct($parser, $xml, $tags)) {
        $elements = array();
      $stack    = array();
      foreach($tags as $tag) {
        $index = count($elements);
        if($tag['type'] == 'complete' || $tag['type'] == 'open') {
          $elements[$tag['tag']]               = array();
          $elements[$tag['tag']]['attributes'] = (array_key_exists('attributes', $tag)) ? $tag['attributes'] : NULL;
          $elements[$tag['tag']]['content']    = (array_key_exists('value', $tag)) ? $tag['value'] : NULL;
          if($tag['type'] == 'open') {
            $elements[$tag['tag']]['children'] = array();
            $stack[count($stack)] = &$elements;
            $elements = &$elements[$tag['tag']]['children'];
          }
        }
        if($tag['type'] == 'close') {
          $elements = &$stack[count($stack) - 1];
          unset($stack[count($stack) - 1]);
        }
      }
      $return_data = $elements;
      } else {
        // not valid xml data
        $return_data = FALSE;
      }
      xml_parser_free($parser);
    return $return_data;
  }
}

?>