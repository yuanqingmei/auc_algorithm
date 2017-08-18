#!/usr/bin/perl -w
#use strict;

use Statistics::Test::WilcoxonRankSum;


sub getAUCandItsVariance_area{
	my $metricData = shift;
	my $changeData = shift;

	my $nornalData = [];                                                 
	my $abnornalData = [];
	my $alln = [];
	my %db;

	my $negative = 0;
	my $positive = 0;		
	
	for (my $i = 0; $i < @{$metricData}; $i++){
		next if ($metricData->[$i] =~ m/und/i);                             
		my $metric = $metricData->[$i];
		if ($changeData->[$i] > 0){
			push @{$abnornalData}, $metricData->[$i];
			push @{$alln}, $metricData->[$i];
			push @{$db->{$metric}->{negative}}, 0;
			push @{$db->{$metric}->{positive}}, 1;
			$negative = $negative + 1;
			
		}else{
		  push @{$nornalData}, $metricData->[$i];
			push @{$alln}, $metricData->[$i];
			push @{$db->{$metric}->{negative}}, 1;
			push @{$db->{$metric}->{positive}}, 0;
			$positive = $positive + 1;
		}
	}
  
	my $tp = 0;
	my $fp = 0;
	my @tpr;
	my @fpr;
 
foreach my $metric ( sort { $b <=> $a } keys %{$db} ) {	

	for (my $i = 0; $i < scalar @{$db->{$metric}->{positive}}; $i++){

		     my $posi = $db->{$metric}->{positive}[$i];
		     my $nega = $db->{$metric}->{negative}[$i];		     
         $tp = $tp + $posi;
         $fp = $fp + $nega;
         my $t = $tp/$positive;
         my $f = $fp/$negative;     		   
         push @tpr,$t;
         push @fpr,$f;   
  
      }

}

   my $auc_area = 0;
   my $prev_x = 0;
  
   for (my $i = 0; $i < scalar @tpr; $i++){
   	 if ($fpr[$i] != $prev_x){
 		 
   		 $auc_area = $auc_area + ($fpr[$i] - $prev_x) * $tpr[$i];

   	 }
   	  $prev_x = $fpr[$i];

   }

 	 %{$db} = (); 	
   
  for (my $i = 0; $i < scalar @tpr; $i++){
    	pop @tpr;
    	pop @fpr;
  }
  
	my $n0 = scalar @{$nornalData};
	my $n1 = scalar @{$abnornalData};

  return(0, 0, 0, 0) if ($n0 * $n1 < 1);
  
	my $wilcox_test = Statistics::Test::WilcoxonRankSum->new();	
	$wilcox_test->load_data($nornalData, $abnornalData);    
	
  my $RankSum = $wilcox_test->rank_sum_for(1);    
  my $MW_U = $RankSum - 0.5 * $n0 * ($n0 + 1);  
  
  my $AUC = ($n0 * $n1 - $MW_U)/($n0*$n1);
  
  my $Q1 = $AUC/(2 - $AUC);
  my $Q2 = 2 * $AUC * $AUC / (1 + $AUC);

  my $variance = $AUC * (1 - $AUC) + ($n1 - 1) * ($Q1 - $AUC * $AUC) + ($n0 - 1) * ($Q2 - $AUC * $AUC);
  $variance = $variance / ($n0 * $n1);
  
  #auc_area
  my $Q1_area = $auc_area/(2 - $auc_area);
  my $Q2_area = 2 * $auc_area * $auc_area / (1 + $auc_area);

  my $variance_area = $auc_area * (1 - $auc_area) + ($n1 - 1) * ($Q1_area - $auc_area * $auc_area) + ($n0 - 1) * ($Q2_area - $auc_area * $auc_area);
  $variance_area = $variance_area / ($n0 * $n1);
  
	return ($AUC, $variance, $n0 + $n1, $auc_area, $variance_area);
}

