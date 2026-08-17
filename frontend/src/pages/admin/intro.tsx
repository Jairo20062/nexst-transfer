import {
  Anchor,
  Button,
  Center,
  Container,
  Stack,
  Text,
  Title,
} from "@mantine/core";
import Link from "next/link";
import Logo from "../../components/Logo";
import Meta from "../../components/Meta";

const Intro = () => {
  return (
    <>
      <Meta title="Intro" />
      <Container size="xs">
        <Stack>
          <Center>
            <Logo height={80} width={80} />
          </Center>
          <Center>
            <Title order={2}>Welcome to Nexst Transfer</Title>
          </Center>
          <Text>
            If you enjoy Nexst Transfer please ⭐️ it on{" "}
            <Anchor
              target="_blank"
              href="https://github.com/smp46/pingvin-share-x"
            >
              GitHub
            </Anchor>{" "}
          </Text>
          <Text>
            You can also support development via{" "}
            <Anchor target="_blank" href="https://github.com/sponsors/smp46">
              GitHub Sponsors ❤️
            </Anchor>{" "}
          </Text>
          <Text>Enough talked, have fun with Nexst Transfer!</Text>
          <Text mt="lg">How to you want to continue?</Text>
          <Stack>
            <Button href="/admin/config/general" component={Link}>
              Customize configuration
            </Button>
            <Button href="/" component={Link} variant="light">
              Explore Nexst Transfer
            </Button>
          </Stack>
        </Stack>
      </Container>
    </>
  );
};

export default Intro;
