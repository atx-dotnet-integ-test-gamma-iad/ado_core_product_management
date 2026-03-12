# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version mismatches. If any packages previously relied on Windows-specific implementations, verify that cross-platform compatible alternatives are in place.

## 3. Build the Solution

Perform a full build in Release configuration to confirm no errors or warnings surface outside of Debug mode:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or platform compatibility (e.g., CA1416 analyzer warnings).

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee runtime correctness, so test coverage is important at this stage.

## 5. Validate Runtime Behavior

Run the application and exercise its core functionality manually, focusing on:

- Any database or ADO.NET related operations, given the project name suggests ADO usage (`AdoCore`).
- Connection string formats, as some providers behave differently on Linux/macOS compared to Windows.
- File path handling, ensuring `Path.Combine` is used rather than hardcoded backslashes.

## 6. Check for Platform-Specific Code

Search the codebase for any remaining Windows-specific APIs that may compile successfully but fail at runtime on non-Windows platforms:

```bash
grep -rn "Registry\|Environment.SpecialFolder\|DllImport" --include="*.cs"
```

Address any findings by replacing them with cross-platform equivalents or adding appropriate runtime platform checks using `RuntimeInformation.IsOSPlatform`.

## 7. Review Configuration Files

Ensure `app.config` or `web.config` files have been replaced or supplemented with `appsettings.json` where applicable, as the `ConfigurationManager` behavior differs in .NET compared to .NET Framework.

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Review the contents of the `publish` output folder before deploying to the target environment.