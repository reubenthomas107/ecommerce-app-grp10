resource "aws_wafv2_web_acl" "ecapp_waf" {
  name        = "ecapp-waf"
  scope       = "REGIONAL"
  description = "WAFv2 for ALB to protect against SQL Injection and XSS Attacks"
 
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "ecapp-waf-metrics"
    sampled_requests_enabled  = true
  }

  default_action {
    allow {}
  }

  #Managed Rules - SQLi, OWASP CoreRuleSet (XSS), PHP
  rule {
    name     = "ECAPP-SQLInjectionProtection"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action { 
      none {} 
    }

    visibility_config {
      sampled_requests_enabled = true
      cloudwatch_metrics_enabled = true
      metric_name               = "ecapp_waf_sql_injection_protection"
    }
  }

  rule {
    name     = "ECAPP-XSS-Protection-CRS"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          action_to_use {
            count {}
          }
          name = "SizeRestrictions_BODY"
        }
      }
      
    }

    override_action { 
      count {} 
    }

    

    visibility_config {
      sampled_requests_enabled = true
      cloudwatch_metrics_enabled = true
      metric_name               = "ecapp_waf_xss_crs_protection"
    }
  }

  rule {
    name     = "ECAPP-PHP-App-Protection"
    priority = 3

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesPHPRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action { 
      none {} 
    }

    visibility_config {
      sampled_requests_enabled    = true
      cloudwatch_metrics_enabled  = true
      metric_name                 = "ecapp_waf_php_attack_protection"
    }
  }
}

#TODO: Custom Rules

resource "aws_wafv2_web_acl_association" "ecapp_waf_alb_association" {
  resource_arn = aws_lb.ecapp_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.ecapp_waf.arn
}

#TODO: Enable CloudWatch Logs