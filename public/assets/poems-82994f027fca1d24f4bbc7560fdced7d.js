$(document).ready(function(){function e(){var e=$("#voice-title").val(),i=$("#voice-poet").val(),o=$("#voice-content").val();$("#keillorbot").attr("disabled","disabled"),Twilio.Device.connect({voice_title:e,voice_poet:i,voice_content:o})}var i=$("#token").data("token");Twilio.Device.setup(i,{debug:!0}),$("#keillorbot").click(function(){e()}),Twilio.Device.disconnect(function(){$("#keillorbot").removeAttr("disabled")})});