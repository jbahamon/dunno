extern number mouseX;
extern number mouseY;
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
{
  vec3 texColor = vec3(texture2D(texture, texture_coords.st));

  float distance = sqrt(pow(pixel_coords.x - mouseX, 2) + pow(pixel_coords.y - mouseY, 2));

  float distanceFromBorder = (distance - 50.0);

  float lightIntensity = 1.0 - tanh(distanceFromBorder * 0.005);

  return vec4(texColor * lightIntensity, 1.0);
}