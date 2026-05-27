from loguru import logger


def configure_logging(level: str = "INFO") -> None:
    logger.remove()
    logger.add(
        sink=lambda msg: print(msg, end=""),
        format="{time} | {level} | {name} | {message}",
        level=level,
    )
