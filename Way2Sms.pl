###################################################################################################################################################################
#Modules to be installed : Mechanize,Date::Calc, LWP::ConnCache, HTTP::Cookies
#$k_phonenum, $k_password : Here you will have to enter your registered phone number and password required to login to way2sms site.
#Function Explantion : -> error_exit: Prints PAGE error if it is an error from the code and exits the script. Prints SITE error if it is fault from the site 
#                         and exits from the script. Prints HTTP error and exits the script if HTTP error occurs at site. Prints USERACT when action from the users
#                         side is required.
#                      -> debug_print : Prints the message required for debugging while running the script.If you do not want debug messages just set $k_debug flag
#                         to zero.
#                      -> get_response_content :Checks if the content received is proper and dumpes the outfile in html format. 
#                      -> do_mech_post : It is used to post form along with it is parameters. Hidden parameters are handled here itself.
###################################################################################################################################################################

use strict;
use WWW::Mechanize;
use LWP::ConnCache;
use HTTP::Cookies;
use Date::Calc qw(Add_Delta_YMD);

my $mech = WWW::Mechanize->new();
$mech->env_proxy();
$mech->conn_cache(LWP::ConnCache->new());

$mech->add_header(
    'User-Agent'      => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1)',
    'Accept'          => '*/*',
    'Accept-Language' => 'en-US',
);
my $contact = {    #Contact number to b added in Hash Of Arrays. It is used to add if more than one phone number present#
    'SP'     => [],
    
};

#Login cred to login to way2sms to be provided#
my $k_phonenum = '';
my $k_password = '';
my ($response, $count, $k_debug, $no_logout) = ('', 0, 1, 1);
my $c;
my $login_URL = 'http://site3.way2sms.com/content/index.html';

main();
exit(0);

sub main {
    debug_print("Logging into way2sms site");
    $response = $mech->get($login_URL);
    get_response_content();

    my $login_action = 'http://site3.way2sms.com/Login1.action';
    my $form_name    = "lgnFrm";
    defined $mech->form_name($form_name)
        ? my $form = $mech->form_name($form_name)
        : error_exit("PAGE", "Form $form_name not found");
    my @input;
    push(@input, "username", $k_phonenum, "password", $k_password, "Submit", "Sign+in");
    $response = do_mech_post($form, \@input, $login_action);
    get_response_content();

    error_exit("USERACT", "Message from Way2Sms Site :\"Oops, looks like you haven`t registered yet.\"") if ($c =~ /Oops\s*\,\s*looks\s+like\s+you\s+haven\`t\s+registered\s+yet/is);
    debug_print("Login success");
    $no_logout = 0;

    my $form_name    = "ebFrm";
    defined $mech->form_name($form_name)
        ? my $form = $mech->form_name($form_name)
        : error_exit("PAGE", "Form $form_name not found");
    my $token = $form->find_input('Token')->value;
    my $action = "http://site3.way2sms.com/sendSMS?Token=$token";
    $response = $mech->get($action);
    get_response_content();

    foreach my $mobile (keys %{$contact}) {
        #While running the script enter the msg you want to send in arg zero place#
        my $msg = $ARGV[0] or die $!;

        $msg = substr($msg, 0, 140);
        my $msg_len = 140 - length($msg);

        $form_name = "smsFrm";
        defined $mech->form_name($form_name)
            ? my $form = $mech->form_name($form_name)
            : error_exit("PAGE", "Form $form_name not found");
        my $token = $form->find_input('Token')->value;
        my $action = 'http://site3.way2sms.com/smstoss.action';
        @input = ();
        debug_print("Posting the msg that is to be sent. Message length is $msg_len");
        push(@input,
            "ssaction",   "ss", "Token", $token,  "mobile",    "91".$contact->{$mobile}[0],
            "message",       $msg, "msgLen",     $msg_len, "Send", "Sending..");
        $response = do_mech_post($form, \@input, $action);
        get_response_content();

        $c =~ /Message has been submitted successfully/is ? debug_print("Success") : debug_print("Failed");
        $mech->back();
    }
    error_exit("PAGE", "Check the parameters")
        if ($c =~ /Sorry\,\s+temporary\s+problem\s+with\s+the\s+service\.\s+Please\s+try\s+again/is);
    do_logout();
}

sub get_response_content {
    $count += 1;
    $c = $response->decoded_content();
    $c = $response->content if (!$c);
    error_exit("SITE", "returned zero byte file") if (length($c) == 0);
    if ($k_debug) {
        my $ct            = $mech->ct;
        my $k_status_line = $response->status_line;
        my $k_url_base    = $response->base;
        my $k_cookies     = $mech->cookie_jar->as_string;
        debug_print("Status Line: $k_status_line");
        debug_print("Content Type: $ct");
        debug_print("Base: $k_url_base");
        $response->is_info     ? debug_print("is_info: yes")     : debug_print("is_info: no");
        $response->is_success  ? debug_print("is_success: yes")  : debug_print("is_success: no");
        $response->is_redirect ? debug_print("is_redirect: yes") : debug_print("is_redirect: no");
        $response->is_error    ? debug_print("is_error: yes")    : debug_print("is_error: no");
        debug_print($k_cookies);
        dump_file($c, "output");
    }
    if ($count > 200) {
        error_exit("PAGE", "Too many URL calls (may be looping). Goodbye!");
    }
    if ($response->is_error) {
        error_exit("HTTP", "Unable to fetch url#$count. Status: " . $response->status_line);
    }
}

sub debug_print {
    my $message = shift;
    print "Fetchdata: $message\n" if ($k_debug);
}

sub dump_file {
    my $local_c  = shift;
    my $prefix   = shift;
    my $filename = $prefix . $count . ".html";
    open(OUTFILE, ">$filename") or error_exit("IO", "Can't open $filename: $!");
    binmode(OUTFILE);
    print OUTFILE $local_c;
    close OUTFILE;
    debug_print("Response dumped in file $filename");
}

sub do_mech_post {
    my $form_object  = shift;    # HTML Form Object that Mech Object is pointing to
    my $input_fields = shift;    # Array Reference containing key-Value pairs non-hidden fields
    my $action      = shift;

    $action = $form_object->action if (!$action);
    my @html_input_objects = $mech->find_all_inputs();
    my $input_obj;
    my $ctr = 0;

    for (my $j = 0; $j < scalar(@html_input_objects); $j++) {
        $input_obj = $html_input_objects[$j];
        for (my $i = 0; $i < scalar(@$input_fields); $i++) {
            if ($input_obj->name eq @$input_fields[$i]) {
                $ctr = 0;
                last;
                $i++;
            } else {
                $ctr = 1;
            }
            $i++;
        }

        if ($input_obj->type eq "hidden" && $ctr) {
            push(@$input_fields, $input_obj->name, $input_obj->value);
        }
    }
    return $mech->post($action, $input_fields);    # $inputFields us array reference
}

sub comma_space_free {
    my $n = shift;
    $n =~ s/\,|\s+|\://gs;
    $n =~ s/<.*?>//sg;
    return $n;
}

sub error_exit {
    my $err_type = shift;
    my $message  = shift;
    if ($c !~ /<\/body.*?>.*?<\/html.*?>/is && $c =~ /<html.*?>/is) {
        debug_print("Looks like incomplete page");
        $err_type = "SITE";
    }
    print "#ERROR $err_type $message\n";
    do_logout();
    sleep(2);
    exit(1);
}

sub do_logout {
    return if ($no_logout == 1);
    $no_logout = 1;
    my $log_url = "entry?ec=0080&id=msg2";
    $response = $mech->get($log_url);
    get_response_content();
    debug_print ("logout success");
}

