from argparse import (
    ArgumentParser,
    ArgumentDefaultsHelpFormatter,
    BooleanOptionalAction,
)
import base64
import binascii
import getpass
import urllib.parse

import matplotlib.pyplot as plt
import qrcode


def main():
    parser = ArgumentParser(
        allow_abbrev=False, formatter_class=ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--issuer", default="issuer", help="Issuer")
    parser.add_argument("--account", default="account", help="Account")
    parser.add_argument("--algorithm", default="sha1", help="Algorithm")
    parser.add_argument("--digits", default=6, type=int, help="Digits")
    parser.add_argument("--period", default=30, type=int, help="Period")
    parser.add_argument("--type", default="totp", help="Type")
    parser.add_argument(
        "--raw",
        action=BooleanOptionalAction,
        default=False,
        help="Raw secret, to be used when input is not already base32-encoded.",
    )

    args = parser.parse_args()

    secret = getpass.getpass("Secret? ")

    if args.raw:
        secret = base64.b32encode(secret.encode("UTF-8")).decode("US-ASCII")
        while secret.endswith("="):
            secret = secret.removesuffix("=")
    else:
        try:
            test_secret = secret.encode("US-ASCII")
            remainder = len(test_secret) % 8
            if remainder > 0:
                test_secret += b"=" * (8 - remainder)
            base64.b32decode(test_secret)
        except binascii.Error as e:
            raise Exception("Do you need to specify --raw?") from e

    parts = (
        "otpauth",
        args.type,
        urllib.parse.quote(args.issuer)
        + ":"
        + urllib.parse.quote(args.account),
        "",
        urllib.parse.urlencode(
            {
                "issuer": args.issuer,
                "algorithm": args.algorithm,
                "digits": args.digits,
                "period": args.period,
                "secret": secret,
            }
        ),
        None,
    )
    url = urllib.parse.urlunparse(parts)

    qr = qrcode.QRCode()
    qr.add_data(url)
    qr.make(fit=True)

    img = qr.make_image()
    # could do `img.save(filename)` instead, but a window avoids writing the
    # temporary file to disk.

    fig = plt.figure(f"{args.issuer} - {args.account}")
    plt.close(plt.figure(0))
    plt.imshow(img, cmap="gray")
    plt.subplots_adjust(bottom=0, top=1, left=0, right=1)
    plt.axis("off")
    plt.show()


if __name__ == "__main__":
    main()
