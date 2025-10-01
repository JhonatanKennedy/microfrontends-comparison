import {
  colors,
  Box,
  Typography,
  IconButton,
  navigateOnButtonPress,
} from "@single-spa/ui-utils";

export function Header() {
  return (
    <Box
      justify="center"
      align="center"
      gap={12}
      style={{
        backgroundColor: colors.primary,
        padding: "30px 0px",
        width: "100%",
        flexWrap: "wrap",
        gap: 0,
      }}
    >
      <Box style={{ flex: 1 }}>
        <IconButton
          icon="arrowLeft"
          size={30}
          name="/"
          onClick={navigateOnButtonPress}
        />
      </Box>

      <Box style={{ flex: 1, justifyContent: "center" }}>
        <Typography
          component="span"
          variant="h1"
          style={{ color: colors.background }}
        >
          LOGO
        </Typography>
      </Box>

      <Box style={{ flex: 1 }} />
    </Box>
  );
}
