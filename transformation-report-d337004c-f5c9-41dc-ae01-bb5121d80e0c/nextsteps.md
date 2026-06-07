# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-specific APIs that may not behave correctly on Linux or macOS:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-only file path assumptions (backslashes, drive letters)
- `System.Drawing` usage (requires `libgdiplus` on non-Windows)

## 5. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

If cross-platform testing is not immediately available, at minimum run on the primary deployment platform and review logs for runtime exceptions.

## 6. Review NuGet Package Compatibility

Check that all NuGet dependencies support the target framework. Open the `.csproj` file and review `<PackageReference>` entries. You can also run:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with improved cross-platform support.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the output in the `./publish` directory to confirm all required files are present.

## 8. Verify Configuration Files

Ensure that any configuration files (e.g., `appsettings.json`, connection strings) have been updated to reflect the new environment and do not contain legacy references to Windows-specific paths or services.