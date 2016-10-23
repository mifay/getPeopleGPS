#!/usr/bin/perl

# Copyright 2016 Michael Fayad
#
# This file is part of getPeopleGps.
#
# This file is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this file.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

my $googleKey = "AIzaSyD9wqmeX_YlaRLZYrnNDOkHcXvlXa9cATo";

# Set Perl not to buffer the printing output
local $| = 1;

use Time::HiRes qw(usleep); # module for sleeping the script in microseconds
use LWP::UserAgent; # pour les requêtes HTTP

my @lieux; # liste des lieux déjà recherchés

my $agent = LWP::UserAgent->new;

open LecteurDeFichier,"<input.txt" or die "E/S : $!\n";
open RedacteurDeFichier,">output.txt" or die $!;

my $min = 3000000; # minimum sleep delay in microseconds
my $range = 1000000; # range of time for random time generation

while (my $Ligne = <LecteurDeFichier>)
{ 
    if($Ligne =~ /^(.+,\"(.+)\",.+)$/)
    {    
	my $lineTrimmed = $1; # without the \n
        my $adr = $2;  # Adresse postale   
        
        my $adr_req = "$adr Montreal";
        $adr_req =~ s/,//g; # remove all ","
        $adr_req =~ s/\s/\+/g; # search and replace all whitespaces for + so it can be used by the following HTTP request              
        
        my $reqHTTP = "https://maps.googleapis.com/maps/api/place/textsearch/xml?query=$adr_req&sensor=false&key=$googleKey&language=fr";
        my $req = HTTP::Request->new(GET => $reqHTTP);
        
        # Envoyer la requête
        my $rep = $agent->request($req);    

        if ($rep->is_success) 
        { 
            my $xml = $rep->decoded_content; 
            
            my $lat;
            my $lng;
            if($xml =~ /<lat>(.*)<\/lat>/)
            {
                $lat = $1;
            }              
           
            if($xml =~ /<lng>(.*)<\/lng>/)
            {
                $lng = $1;
            }                 
                
            print RedacteurDeFichier "$lineTrimmed,$lat,$lng\n";
        }
        
        #Trick google places api restriction to automate GPS coordinates acquisition
        my $sleepTime = rand($range) + $min;
        usleep($sleepTime);
    }
}
close LecteurDeFichier;
close RedacteurDeFichier;
