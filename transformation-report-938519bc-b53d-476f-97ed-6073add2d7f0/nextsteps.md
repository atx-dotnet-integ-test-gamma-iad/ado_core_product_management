# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that may have been replaced during the transformation.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no configuration-specific issues:

```bash
dotnet build --configuration Release
```

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failures may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Check for Runtime-Specific API Usage

Even if the build succeeds, some APIs may have been removed or behave differently on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining platform-specific calls:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Web` references (not available cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions

## 6. Run the Application

Execute the application directly to confirm it starts and behaves as expected:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Test the primary workflows that were present in the legacy project to confirm functional parity.

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate for your deployment target.

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory and deploy to the target environment using your standard file deployment process.