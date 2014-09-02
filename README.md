Way2Sms
=======

If you are a registered user of way2sms site and want to send message without entering the site in browser.
Then check this out.
Now coming to the part how can you use the script, read the following.
#While running the script enter the msg you want to send in arg zero place#
#Modules to be installed : Mechanize,Date::Calc, LWP::ConnCache, HTTP::Cookies
#$k_phonenum, $k_password : Here you will have to enter your registered phone number and password required to login to way2sms site.
#Function Explantion : -> error_exit: Prints PAGE error if it is an error from the code and exits the script. Prints SITE error if it is fault from the site 
                         and exits from the script. Prints HTTP error and exits the script if HTTP error occurs at site. Prints USERACT when action from the users
                         side is required.
                      -> debug_print : Prints the message required for debugging while running the script.If you do not want debug messages just set $k_debug flag
                         to zero.
                      -> get_response_content :Checks if the content received is proper and dumpes the outfile in html format. 
                      -> do_mech_post : It is used to post form along with it is parameters. Hidden parameters are handled here itself.
#Comments are also added in the script for help you understand the script.
